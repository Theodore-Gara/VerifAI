require('dotenv').config();

const fs = require('fs');
const path = require('path');
const pool = require('../db/pool');

// Usage:
//   node scripts/db-setup.js           fresh database  -> schema.sql  + seed.sql
//   node scripts/db-setup.js migrate   existing prototype -> migrate_d4.sql + seed.sql
const mode = process.argv[2] === 'migrate' ? 'migrate' : 'fresh';
const files = mode === 'migrate'
  ? ['migrate_d4.sql', 'seed.sql']
  : ['schema.sql', 'seed.sql'];

(async () => {
  if (!process.env.DATABASE_URL) {
    console.error('DATABASE_URL is not set. Copy .env.example to .env and fill it in.');
    process.exit(1);
  }

  let client;
  try {
    client = await pool.connect();
    for (const file of files) {
      const sql = fs.readFileSync(path.join(__dirname, '..', 'db', file), 'utf8');
      process.stdout.write(`${file} ... `);
      await client.query(sql);
      console.log('ok');
    }

    const { rows } = await client.query(
      "select table_name from information_schema.tables where table_schema = 'public' order by table_name"
    );
    console.log(`\n${rows.length} tables present:`);
    for (const row of rows) {
      console.log(`  - ${row.table_name}`);
    }
  } catch (err) {
    console.error(`\nFAILED: ${err.message}`);
    if (err.code === 'ENOTFOUND') {
      console.error('Check DATABASE_URL: the host is not a real hostname.');
    } else if (err.code === '28P01') {
      console.error('Check DATABASE_URL: the password was rejected.');
    } else if (err.code === 'ECONNREFUSED') {
      console.error('Check DATABASE_URL: wrong port, or the service is not running.');
    } else if (/certificate|self.signed|SSL/i.test(err.message)) {
      console.error('SSL negotiation failed. Railway public endpoints require SSL.');
    }
    process.exitCode = 1;
  } finally {
    if (client) client.release();
    await pool.end();
  }
})();
