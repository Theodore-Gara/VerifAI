-- Remove the original prototype/seed accounts and the prototype backup table.
-- Seed accounts are gone; real accounts are created by Firebase sign-in.

DELETE FROM users
WHERE firebase_uid IN (
  'theo@verif.com',
  'vusani@verif.com',
  'naledi@verif.com',
  'mpho@verif.com',
  'meshaque@verif.com'
);

DROP TABLE IF EXISTS prototype_backup;
