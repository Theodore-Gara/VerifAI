// Small in-process TTL cache used for read-heavy, rarely-changing payloads
// (analytics rollups, the leaderboard board, static content catalogues).
//
// This is deliberately not a distributed cache: the API runs as one instance
// today, and every caller can tolerate the staleness a short TTL introduces.
// `wrap()` coalesces concurrent misses so a burst of requests triggers one
// query rather than one per request.

class TtlCache {
  constructor({ ttlMs = 60000, maxEntries = 500 } = {}) {
    this.ttlMs = ttlMs;
    this.maxEntries = maxEntries;
    this.entries = new Map();
    this.inFlight = new Map();
    this.hits = 0;
    this.misses = 0;
  }

  get(key) {
    const entry = this.entries.get(key);
    if (!entry) return undefined;
    if (entry.expiresAt <= Date.now()) {
      this.entries.delete(key);
      return undefined;
    }
    // Refresh LRU position: Map keeps insertion order.
    this.entries.delete(key);
    this.entries.set(key, entry);
    return entry.value;
  }

  set(key, value) {
    if (this.entries.size >= this.maxEntries) {
      const oldest = this.entries.keys().next().value;
      if (oldest !== undefined) this.entries.delete(oldest);
    }
    this.entries.set(key, { value, expiresAt: Date.now() + this.ttlMs });
    return value;
  }

  delete(key) {
    this.entries.delete(key);
    return true;
  }

  clear() {
    this.entries.clear();
    this.inFlight.clear();
    this.hits = 0;
    this.misses = 0;
  }

  /**
   * Returns the cached value for `key`, or runs `producer()` once and caches the
   * result. A rejected producer is never cached, so a transient database error
   * does not pin an error response for a whole TTL.
   */
  async wrap(key, producer) {
    const cached = this.get(key);
    if (cached !== undefined) {
      this.hits += 1;
      return cached;
    }
    if (this.inFlight.has(key)) return this.inFlight.get(key);
    this.misses += 1;
    const pending = (async () => {
      try {
        const value = await producer();
        return this.set(key, value);
      } finally {
        this.inFlight.delete(key);
      }
    })();
    this.inFlight.set(key, pending);
    return pending;
  }
}

// Shared caches. Exported individually so the owning module can invalidate just
// its own slice (an admin editing a task should not flush the leaderboard).
const analyticsCache = new TtlCache({ ttlMs: Number(process.env.ANALYTICS_CACHE_MS) || 60000 });
const leaderboardCache = new TtlCache({ ttlMs: Number(process.env.LEADERBOARD_CACHE_MS) || 60000 });
const contentCache = new TtlCache({ ttlMs: Number(process.env.CONTENT_CACHE_MS) || 60000 });

module.exports = { TtlCache, analyticsCache, leaderboardCache, contentCache };
