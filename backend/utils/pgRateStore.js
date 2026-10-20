// Rate-limit store backed by PostgreSQL so the budget is shared by every API
// instance instead of being counted per process. `express-rate-limit`'s default
// MemoryStore meant a second Render instance doubled everyone's allowance (and
// the AI budget with it).
//
// The store falls back to an in-process counter when a query fails: losing rate
// limiting for a moment is far better than failing every request because the
// limiter itself is down. The fallback is also what keeps the unit tests (which
// mock `pg`) working without a database.
const defaultPool = require('../db/pool');

const TABLE = 'rate_limit_hits';

class PostgresRateLimitStore {
  constructor({ pool = defaultPool, prefix = '' } = {}) {
    this.pool = pool;
    this.prefix = prefix;
    this.windowMs = 15 * 60 * 1000;
    this.local = new Map();
    this.dbFailures = 0;
  }

  init(options = {}) {
    if (Number(options.windowMs) > 0) this.windowMs = Number(options.windowMs);
  }

  key(key) {
    return this.prefix ? `${this.prefix}:${key}` : String(key);
  }

  windowStart(now = Date.now()) {
    return Math.floor(now / this.windowMs) * this.windowMs;
  }

  localIncrement(key, resetTime) {
    const entry = this.local.get(key);
    const now = Date.now();
    if (!entry || entry.resetTime.getTime() <= now) {
      const next = { hits: 1, resetTime };
      this.local.set(key, next);
      return { totalHits: next.hits, resetTime };
    }
    entry.hits += 1;
    return { totalHits: entry.hits, resetTime: entry.resetTime };
  }

  async increment(key) {
    const now = Date.now();
    const windowStart = new Date(this.windowStart(now));
    const resetTime = new Date(windowStart.getTime() + this.windowMs);
    const storeKey = this.key(key);
    try {
      const result = await this.pool.query(
        `INSERT INTO ${TABLE} AS r (key, window_start, hits)
         VALUES ($1, $2, 1)
         ON CONFLICT (key, window_start) DO UPDATE SET hits = r.hits + 1
         RETURNING hits`,
        [storeKey, windowStart],
      );
      const hits = Number(result?.rows?.[0]?.hits);
      if (!Number.isFinite(hits)) throw new Error('rate limit store returned no row');
      if (this.dbFailures > 0) this.dbFailures = 0;
      return { totalHits: hits, resetTime };
    } catch (err) {
      this.dbFailures += 1;
      if (this.dbFailures === 1) {
        console.warn('Rate limit store fell back to memory:', err.message);
      }
      return this.localIncrement(key, resetTime);
    }
  }

  async decrement(key) {
    const storeKey = this.key(key);
    try {
      await this.pool.query(
        `UPDATE ${TABLE} SET hits = GREATEST(hits - 1, 0)
         WHERE key = $1 AND window_start = to_timestamp($2 / 1000.0)`,
        [storeKey, this.windowStart()],
      );
    } catch {
      const entry = this.local.get(key);
      if (entry && entry.hits > 0) entry.hits -= 1;
    }
  }

  async resetKey(key) {
    const storeKey = this.key(key);
    this.local.delete(key);
    try {
      await this.pool.query(`DELETE FROM ${TABLE} WHERE key = $1`, [storeKey]);
    } catch {
      // The fallback counter was already cleared; the database row expires with
      // its window.
    }
  }

  /** Drops windows that can no longer be counted against any request. */
  async prune() {
    try {
      await this.pool.query(
        `DELETE FROM ${TABLE} WHERE window_start < CURRENT_TIMESTAMP - INTERVAL '1 day'`,
      );
      return true;
    } catch {
      return false;
    }
  }
}

module.exports = { PostgresRateLimitStore };
