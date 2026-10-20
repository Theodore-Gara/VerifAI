-- 69_admin_seed.sql — bootstrap the super-admin account.
--
-- Inserts vusani@verify.com into admin_accounts with the 'super' role so the
-- account can sign in with normal Firebase credentials (same flow as learners)
-- and immediately access the admin panel at /admin. The ADMIN_EMAILS allowlist
-- in backend/.env (and local-db.js) must contain this address for the
-- isAdmin middleware to recognise it.
--
-- Idempotent: re-running only refreshes the role/added_by metadata.

INSERT INTO admin_accounts (email, role, added_by)
VALUES ('vusani@verify.com', 'super', 'seed')
ON CONFLICT (email) DO UPDATE SET
  role = EXCLUDED.role,
  added_by = EXCLUDED.added_by;
