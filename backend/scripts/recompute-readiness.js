require('dotenv').config();
const pool = require('../db/pool');
const { refreshReadiness } = require('../services/readinessService');

// One-off repair: skill scores are coverage (passed tasks / tasks available per
// feature) and readiness used to be stored monotonically via GREATEST, so a
// stale high value could never be cleared. This recomputes every user's skill
// scores from their attempts, then recomputes readiness and the tier it drives.
const FEATURE_DIMENSION = {
  verification: 'Verification',
  judgement: 'AI Judgement',
  risk_governance: 'Risk & Governance',
  prompt_design: 'Prompt Design',
};

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    for (const [feature, dimension] of Object.entries(FEATURE_DIMENSION)) {
      const res = await client.query(
        `INSERT INTO skill_scores (user_id, dimension, score, attempts_count, updated_at)
         SELECT u.id, $2,
                CASE WHEN tot.n > 0
                     THEN ROUND((100.0 * (f.n + 0.5 * p.n)) / tot.n)::int
                     ELSE 0 END,
                COALESCE(att.n, 0), CURRENT_TIMESTAMP
         FROM users u
         JOIN LATERAL (SELECT COUNT(*)::int AS n FROM tasks t
                        WHERE t.feature = $1 AND t.track_id = u.industry_track_id) tot ON TRUE
         LEFT JOIN LATERAL (SELECT COUNT(DISTINCT ta.task_id)::int AS n
                        FROM task_attempts ta JOIN tasks t ON t.id = ta.task_id
                        WHERE ta.user_id = u.id AND ta.practice = FALSE AND ta.passed
                          AND t.feature = $1 AND t.track_id = u.industry_track_id) f ON TRUE
         LEFT JOIN LATERAL (SELECT COUNT(DISTINCT ta.task_id)::int AS n
                        FROM task_attempts ta JOIN tasks t ON t.id = ta.task_id
                        WHERE ta.user_id = u.id AND ta.practice = TRUE AND ta.passed
                          AND t.feature = $1 AND t.track_id = u.industry_track_id
                          AND NOT EXISTS (SELECT 1 FROM task_attempts fp
                             WHERE fp.user_id = u.id AND fp.task_id = ta.task_id
                               AND fp.practice = FALSE AND fp.passed)) p ON TRUE
         LEFT JOIN LATERAL (SELECT COUNT(*)::int AS n
                        FROM task_attempts ta JOIN tasks t ON t.id = ta.task_id
                        WHERE ta.user_id = u.id AND t.feature = $1
                          AND t.track_id = u.industry_track_id) att ON TRUE
         WHERE u.industry_track_id IS NOT NULL
           AND (COALESCE(f.n, 0) > 0 OR COALESCE(p.n, 0) > 0 OR COALESCE(att.n, 0) > 0)
         ON CONFLICT (user_id, dimension) DO UPDATE SET
           score = EXCLUDED.score,
           attempts_count = EXCLUDED.attempts_count,
           updated_at = CURRENT_TIMESTAMP`,
        [feature, dimension]
      );
      console.log(`  ${feature}: ${res.rowCount} skill row(s) recomputed`);
    }

    const users = await client.query('SELECT id, industry_track_id FROM users');
    for (const user of users.rows) {
      await refreshReadiness(client, user.id, user.industry_track_id);
    }
    console.log(`  readiness + tier recomputed for ${users.rows.length} user(s)`);

    if (dryRun) {
      await client.query('ROLLBACK');
      console.log('Dry run: rolled back, nothing persisted.');
    } else {
      await client.query('COMMIT');
      console.log('Done.');
    }
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    console.error(`FAILED: ${err.message}`);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

if (require.main === module) main();
