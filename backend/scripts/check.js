const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const roots = ['controllers', 'routes', 'middleware', 'services', 'db', 'tests', 'scripts'];
const files = [];

function walk(dir) {
  if (!fs.existsSync(dir)) return;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (entry.isFile() && full.endsWith('.js')) files.push(full);
  }
}

for (const root of roots) walk(path.join(process.cwd(), root));
files.push(path.join(process.cwd(), 'app.js'), path.join(process.cwd(), 'server.js'));

let failed = false;
for (const file of files) {
  const result = spawnSync(process.execPath, ['--check', file], { stdio: 'inherit' });
  if (result.status !== 0) failed = true;
}

if (failed) process.exit(1);
console.log(`Syntax check passed for ${files.length} JavaScript files.`);
