const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { test } = require('node:test');

// The seeds are the content source of truth, and the suite has no live
// database, so these tests read the SQL files directly: shape, completeness,
// idempotency rules and "no placeholder" are all properties of the files.
const SEED_DIR = path.join(__dirname, '..', 'db', 'seed');
const read = (f) => fs.readFileSync(path.join(SEED_DIR, f), 'utf8');

const helpSql = read('70_support_help.sql');
const faqSql = read('71_support_faqs.sql');
const guideSql = read('72_industry_guides.sql');
const tourSql = read('78_support_tours.sql');

const statements = (sql) => sql.split(/;\s*\n\s*\n/).filter((s) => /INSERT INTO/.test(s));
const firstValue = (stmt) => /VALUES \('([^']+)'/.exec(stmt)?.[1] || /SELECT (?:it\.id, )?'([^']+)'/.exec(stmt)?.[1];
const md = (stmt) => [...stmt.matchAll(/\$md\$([\s\S]*?)\$md\$/g)].map((m) => m[1]);
const json = (stmt) => [...stmt.matchAll(/\$j\$([\s\S]*?)\$j\$/g)].map((m) => JSON.parse(m[1]));

const PLACEHOLDER = /lorem|ipsum|todo|tbd|placeholder|coming soon|xxx|\[insert/i;

test('help seed: ten articles, unique slugs, idempotent upsert on slug', () => {
  const stmts = statements(helpSql).filter((s) => s.includes('INTO help_articles'));
  const slugs = stmts.map(firstValue);
  assert.equal(stmts.length, 10);
  assert.equal(new Set(slugs).size, 10, 'slugs are unique');
  for (const stmt of stmts) {
    assert.match(stmt, /ON CONFLICT \(slug\) DO UPDATE/);
    // An admin edit (newer updated_at) must survive a re-seed.
    assert.match(stmt, /WHERE help_articles\.updated_at <= EXCLUDED\.updated_at/);
  }
  for (const wanted of ['what-is-verifai', 'getting-around-the-app', 'choosing-and-changing-your-industry',
    'dashboard-cards-explained', 'learn-ai-lab', 'practice-and-skill-scenarios', 'verification-studio',
    'vera-the-assistant', 'progress-xp-streaks-achievements-tokens', 'troubleshooting']) {
    assert.ok(slugs.includes(wanted), `article ${wanted}`);
  }
});

test('FAQ seed: exactly the ten QA questions with real answers', () => {
  const stmts = statements(faqSql);
  assert.equal(stmts.length, 10);
  assert.equal(new Set(stmts.map(firstValue)).size, 10);
  const questions = stmts.map((s) => /VALUES \('[^']+', '((?:[^']|'')+)'/.exec(s)[1]);
  const expected = [
    /what is verifai/i, /change my industry/i, /skip the tutorial/i, /learn and practice/i,
    /verification studio/i, /use vera/i, /readiness score/i, /xp, streaks/i, /verification fail/i, /log out/i,
  ];
  expected.forEach((re, i) => assert.match(questions[i], re));
  for (const stmt of stmts) {
    assert.match(stmt, /ON CONFLICT \(slug\) DO UPDATE/);
    assert.ok(md(stmt)[0].length > 80, 'answer is substantive');
  }
});

test('guides seed: four industries, nine sections each, in the same structure', () => {
  const stmts = statements(guideSql);
  assert.equal(stmts.length, 4);
  assert.deepEqual(stmts.map(firstValue), ['finance', 'legal', 'it-software', 'business-consulting']);
  const faqSlugs = statements(faqSql).map(firstValue);

  for (const stmt of stmts) {
    const slug = firstValue(stmt);
    assert.match(stmt, /ON CONFLICT \(track_id\) DO UPDATE/);
    const [overview] = md(stmt);
    assert.equal(overview.split(/\r?\n\r?\n/).length, 2, `${slug}: overview is two paragraphs`);
    const [outcomes, tour, howTo] = json(stmt);
    assert.ok(outcomes.who_for && outcomes.by_the_end.length >= 3, `${slug}: who it is for and outcomes`);

    const skills = tour.find((s) => s.key === 'skills').items;
    assert.deepEqual(skills.map((s) => s.name), ['Verification', 'AI Judgement', 'Risk & Governance', 'Prompt Design']);
    for (const s of skills) assert.ok(s.example && s.what_to_check, `${slug}/${s.name}: example and what to check`);

    assert.ok(tour.find((s) => s.key === 'dashboard').body_md.length > 40);
    const features = tour.find((s) => s.key === 'features').items.map((f) => f.feature);
    assert.deepEqual(features, ['Learn', 'Practice', 'Verification Studio', 'Vera', 'Tasks', 'Progress']);

    assert.equal(howTo.first_session.length, 5, `${slug}: five-step first session`);
    assert.equal(howTo.first_session.reduce((n, s) => n + s.minutes, 0), 15, `${slug}: fifteen minutes`);
    assert.ok(howTo.common_mistakes.length >= 4);
    assert.equal(howTo.related_faqs.length, 3);
    for (const f of howTo.related_faqs) assert.ok(faqSlugs.includes(f), `${slug}: related FAQ ${f} exists`);

    assert.match(stmt, new RegExp(`'guide-${slug}-hero', 'guide-${slug}-body'`), `${slug}: image keys`);
  }
});

test('tours seed: a global tour plus one per industry, all with a transcript and unique step ids', () => {
  const stmts = statements(tourSql);
  assert.equal(stmts.length, 5);
  assert.deepEqual(stmts.map(firstValue), ['global-v1', 'finance-v1', 'legal-v1', 'it-software-v1', 'business-consulting-v1']);
  const globalIds = new Set(json(stmts[0])[0].map((s) => s.id));
  for (const stmt of stmts) {
    assert.match(stmt, /ON CONFLICT \(tour_key\) DO UPDATE/);
    const steps = json(stmt)[0];
    assert.ok(steps.length >= 3);
    for (const step of steps) {
      assert.ok(step.id && step.title && step.body_md.length > 40, 'transcript present');
      assert.equal(step.media, null, 'media is null until recordings are hosted');
    }
    assert.equal(new Set(steps.map((s) => s.id)).size, steps.length);
  }
  for (const stmt of stmts.slice(1)) {
    for (const step of json(stmt)[0]) assert.ok(!globalIds.has(step.id), 'industry step ids do not collide with global ones');
  }
  const globalText = json(stmts[0])[0].map((s) => s.id).join(',');
  assert.equal(globalText, 'dashboard,start-a-task,vera,menu,progress');
});

test('no placeholder text, raw HTML or invented statistics in any support seed', () => {
  for (const [name, sql] of [['70', helpSql], ['71', faqSql], ['72', guideSql], ['78', tourSql]]) {
    const body = sql.split('\n').filter((l) => !l.startsWith('--')).join('\n');
    assert.doesNotMatch(body, PLACEHOLDER, `seed ${name}`);
    assert.doesNotMatch(body, /<\/?(div|span|p|br|script|img|a|b|i|table)\b/i, `seed ${name}: markdown only`);
    // No percentages or "N%" claims about outcomes; tier thresholds are plain numbers.
    assert.doesNotMatch(body, /\d+\s*%/, `seed ${name}: no statistics`);
  }
});

test('markdown dollar-quote tags are balanced and the About page is seeded', () => {
  for (const sql of [helpSql, faqSql, guideSql, tourSql]) {
    assert.equal((sql.match(/\$md\$/g) || []).length % 2, 0);
    assert.equal((sql.match(/\$j\$/g) || []).length % 2, 0);
  }
  assert.match(helpSql, /INSERT INTO support_pages[\s\S]*'about'/);
  const [about] = json(helpSql.slice(helpSql.indexOf('INSERT INTO support_pages')));
  for (const key of ['mission_md', 'vision_md', 'south_africa_md', 'how_it_helps_md', 'who_for_md']) {
    assert.ok(about[key] && about[key].length > 40, key);
  }
  assert.equal(about.how_it_works.length, 4);
});

test('migrations and schema.sql define every support table once', () => {
  const schema = fs.readFileSync(path.join(__dirname, '..', 'db', 'schema.sql'), 'utf8');
  for (const table of ['help_articles', 'faqs', 'industry_guides', 'support_tours', 'support_pages',
    'support_messages', 'support_events', 'roadmap_stages', 'roadmap_milestones']) {
    assert.equal((schema.match(new RegExp(`CREATE TABLE IF NOT EXISTS ${table} \\(`, 'g')) || []).length, 1, table);
  }
  assert.match(schema, /'support_content_update', 'support_message_update'/);
  const migrations = fs.readdirSync(path.join(__dirname, '..', 'db', 'migrations'));
  for (const prefix of ['032_', '033_', '035_']) assert.ok(migrations.some((m) => m.startsWith(prefix)), prefix);
});
