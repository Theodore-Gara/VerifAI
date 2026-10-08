-- Verification — IT / Software (6 tasks)
-- Source: IT_Software_Research_Scenarios.docx.

SELECT seed_verification(
  'verification-it-01', 'IT / Software',
  $$The Cart That Adds Objects$$,
  $$An AI coding assistant writes a shopping-cart function. Instead of calculating price times quantity, it adds the item objects to the total directly. The code runs without an obvious error in some cases.$$,
  $$The function sums item objects instead of price x quantity, so the total is wrong. It may run without raising an error, which makes the bug easy to miss.$$,
  $$Correct the function to multiply price by quantity before summing, and add a test asserting the expected total.$$,
  $$Working code is not the same as correct code. A total that is quietly wrong reaches customers and finance. Verify the calculation against expected totals before shipping.$$,
  'easy',
  $j$[
    {"label":"Fix it to multiply price by quantity and add a test for the total.","score":100},
    {"label":"Ship it; the code runs without errors.","score":0},
    {"label":"Wrap the total calculation in a try/catch.","score":0},
    {"label":"Round the total to avoid floating-point issues.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-it-02', 'IT / Software',
  $$The Function That Doesn't Exist$$,
  $$You ask an AI how to use a software library and it points you to a function called authenticateUserSecurely(). Before adding it to the project, you check the official documentation and find that the function does not exist.$$,
  $$The function is hallucinated. AI assistants frequently invent plausible-sounding API and library names that do not exist.$$,
  $$Verify AI-suggested APIs against the official documentation before use, and replace the invented function with the documented equivalent.$$,
  $$Hallucinated APIs waste time and can push developers toward broken or insecure workarounds. Documentation is the only reliable source.$$,
  'easy',
  $j$[
    {"label":"Check the official docs and use the documented function instead.","score":100},
    {"label":"Call authenticateUserSecurely() and see whether it works.","score":0},
    {"label":"Implement authenticateUserSecurely() yourself.","score":0},
    {"label":"Ask the AI for a code sample that uses it.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-it-03', 'IT / Software',
  $$The AI That Says Tests Pass$$,
  $$An AI assistant reviews a pull request and reports that all tests pass and the code is ready to merge. The new code, however, changes the application's payment-processing logic, and none of the existing tests cover the new logic.$$,
  $$Passing existing tests says nothing about logic that no test covers. A change to payment handling needs human review and new tests before merging.$$,
  $$Require review by the person who owns the payments module, add tests for the new logic, and verify before merging.$$,
  $$AI confidence is not the same as correctness. Automation can speed delivery without removing review and testing gates - especially on money-handling code.$$,
  'medium',
  $j$[
    {"label":"Have the payments module owner review, add tests, then merge.","score":100},
    {"label":"Merge; all tests pass.","score":0},
    {"label":"Merge behind a feature flag without review.","score":0},
    {"label":"Ask the AI to write the missing tests and merge.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-it-04', 'IT / Software',
  $$The Working Query That's Insecure$$,
  $$An AI generates a database query that works correctly during testing, but it inserts user input directly into the query string.$$,
  $$Directly concatenating user input into the query introduces a SQL injection vulnerability. The query works, which is exactly why the flaw is easy to miss.$$,
  $$Rewrite the query using parameterised statements and run a security review before deploying.$$,
  $$Working code is not automatically secure code. SQL injection is a classic vulnerability in AI-generated database code and a common breach vector.$$,
  'medium',
  $j$[
    {"label":"Rewrite it with parameterised queries and security-review it.","score":100},
    {"label":"Ship it; the query works in testing.","score":0},
    {"label":"Escape quotes manually and ship.","score":0},
    {"label":"Add a code comment noting the risk.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-it-05', 'IT / Software',
  $$The Catch-All That Hides Bugs$$,
  $$AI writes code that catches every exception with a single broad catch (Exception e) block and just displays 'Something went wrong.'$$,
  $$A single broad catch swallows every error, hiding the information needed to diagnose and fix real problems.$$,
  $$Catch specific exceptions, log the details, and surface actionable errors instead of one generic message.$$,
  $$Over-broad error handling hides failures and makes production issues far harder to diagnose - it can mask security and data-integrity problems.$$,
  'medium',
  $j$[
    {"label":"Catch specific exceptions and log the details instead.","score":100},
    {"label":"Keep it; users get a friendly message.","score":0},
    {"label":"Add more log lines inside the same catch.","score":0},
    {"label":"Remove error handling entirely.","score":0}
  ]$j$::jsonb
);

SELECT seed_verification(
  'verification-it-06', 'IT / Software',
  $$The Dependency With a Known Vulnerability$$,
  $$AI recommends a dependency version for the project. The version carries a known vulnerability and has reached end of life.$$,
  $$The recommended version is end-of-life and carries a known vulnerability. AI training data may be outdated, so version recommendations can lag current security advisories.$$,
  $$Check the version's support status and security advisories, and use a supported, patched version instead.$$,
  $$Adopting an unsupported, vulnerable dependency imports known risk into the codebase and supply chain. Always verify current support and security before adopting a version.$$,
  'medium',
  $j$[
    {"label":"Check support status and advisories; use a supported, patched version.","score":100},
    {"label":"Use it; the AI recommended it.","score":0},
    {"label":"Use it but pin the version.","score":0},
    {"label":"Use the latest alpha release instead.","score":0}
  ]$j$::jsonb
);

-- ===========================================================================
-- Additional line_text tasks (9) — VerifAI_IT_Software_Verification_Tasks.pdf
-- ===========================================================================

SELECT seed_verification_text(
  'verification-it-07', 'IT / Software', $$The Missing First Page$$,
  $$The Flutter app shows a list of tasks from a Node.js API. Pages are numbered from 1 (page=1 is the first page). QA reports that the first 10 tasks never appear. AI wrote the pagination helper.$$,
  'easy',
  ARRAY[
    $$// GET /api/tasks?page=1&pageSize=10   (pages start at 1)$$,
    $$function paginate(items, page, pageSize) {$$,
    $$  const start = page * pageSize;$$,
    $$  const end = start + pageSize;$$,
    $$  return items.slice(start, end);$$,
    $$}$$
  ],
  ARRAY[3],
  $$Line 3. The start index treats pages as if they began at 0.$$,
  $$Use const start = (page - 1) * pageSize;. With page = 1 and pageSize = 10 the slice is items 0 to 9. The AI version returns items 10 to 19 for page 1, so the first page is skipped and the last page can come back empty.$$,
  $$Off-by-one errors are among the most common bugs in code from any source. Users silently never see some records, and nothing crashes, so the bug is easy to miss without a test of page 1.$$,
  ARRAY[$$(page - 1)|page - 1$$, $$pageSize$$],
  ARRAY[$$off-by-one|off by one$$, $$1-based|one-based$$, $$first page$$, $$skip$$]
);

SELECT seed_verification_text(
  'verification-it-08', 'IT / Software', $$The Truncated Average$$,
  $$A reporting feature in a Java back end calculates a student's average score. A student scored 17 marks over 4 attempts and the report shows 4.0 instead of 4.25.$$,
  'easy',
  ARRAY[
    $$int totalScore = 17;$$,
    $$int attempts = 4;$$,
    $$double average = totalScore / attempts;$$,
    $$System.out.println("Average score: " + average);$$,
    $$// prints: Average score: 4.0$$
  ],
  ARRAY[3],
  $$Line 3. Both operands are int, so Java does integer division and drops the decimal part before assigning to a double.$$,
  $$Cast before dividing: double average = (double) totalScore / attempts; (or totalScore / (double) attempts). The result is 4.25.$$,
  $$The result is stored in a double, which makes it look as if the decimal was handled. Rounded-down averages can change grades and rankings without any error message.$$,
  ARRAY[$$(double)|cast$$, $$4.25$$],
  ARRAY[$$integer division$$, $$truncate$$, $$int$$, $$decimal$$]
);

SELECT seed_verification_text(
  'verification-it-09', 'IT / Software', $$The Always-Admin Check$$,
  $$An admin-only endpoint lets users delete accounts. During testing, a normal user managed to delete someone else's account. AI wrote the permission check.$$,
  'easy',
  ARRAY[
    $$function canDeleteUser(currentUser) {$$,
    $$  if (currentUser.role = 'admin') {$$,
    $$    return true;$$,
    $$  }$$,
    $$  return false;$$,
    $$}$$
  ],
  ARRAY[2],
  $$Line 2. A single equals sign assigns the value 'admin' instead of comparing it.$$,
  $$Use a comparison: if (currentUser.role === 'admin'). The AI version sets the role to 'admin' and the assignment is truthy, so the function returns true for every user.$$,
  $$This is a privilege escalation: every logged-in user gets admin rights. A linter rule against assignment in conditions and a test for a non-admin user would both catch it.$$,
  ARRAY[$$===$$, $$comparison$$],
  ARRAY[$$assignment$$, $$every user$$, $$admin$$, $$privilege$$, $$authoris|authoriz$$]
);

SELECT seed_verification_text(
  'verification-it-10', 'IT / Software', $$The Doubled Revenue$$,
  $$A dashboard shows revenue per customer for an online store. Order 1001 totals R1,000 and has 3 items, but the dashboard shows that customer's revenue as R3,000. AI wrote the query.$$,
  'medium',
  ARRAY[
    $$-- tables: customers(id, name), orders(id, customer_id, total),$$,
    $$--         order_items(id, order_id, product, qty)$$,
    $$SELECT c.name, SUM(o.total) AS revenue$$,
    $$FROM customers c$$,
    $$JOIN orders o ON o.customer_id = c.id$$,
    $$JOIN order_items i ON i.order_id = o.id$$,
    $$GROUP BY c.name;$$
  ],
  ARRAY[6],
  $$Line 6. Joining order_items repeats each order row once per item, so the order total is summed several times.$$,
  $$Remove the join to order_items, since no item column is used: FROM customers c JOIN orders o ON o.customer_id = c.id GROUP BY c.name. If item data is needed, aggregate it in a subquery first, then join. SUM(DISTINCT o.total) is not a safe fix because two different orders with the same total would be counted once.$$,
  $$The numbers look plausible, so the error can reach a board report unnoticed. Always compare an aggregate against a known order in the data before you trust the query.$$,
  ARRAY[$$remove the join|remove join$$, $$subquery$$, $$order_items$$],
  ARRAY[$$duplicate$$, $$fan-out|fan out$$, $$three times$$, $$one row per item$$]
);

SELECT seed_verification_text(
  'verification-it-11', 'IT / Software', $$The Floating Rands$$,
  $$A payments job checks that the amount received matches the invoice total. Customers keep getting flagged for mismatches even though they paid exactly R35.60. AI wrote the check.$$,
  'medium',
  ARRAY[
    $$prices = [12.10, 15.30, 8.20]$$,
    $$total = 0.0$$,
    $$for p in prices:$$,
    $$    total += p$$,
    $$$$,
    $$if total == 35.60:$$,
    $$    print('Payment matches invoice')$$,
    $$else:$$,
    $$    print('Payment mismatch - flag for review')$$
  ],
  ARRAY[4, 6],
  $$Lines 4 and 6. Money is added and compared as floating-point numbers, which cannot represent most decimal amounts exactly.$$,
  $$Use integer cents or the Decimal type: from decimal import Decimal then prices = [Decimal('12.10'), Decimal('15.30'), Decimal('8.20')] and compare total == Decimal('35.60'). In floating point, 12.10 + 15.30 + 8.20 is not exactly 35.6, so the equality test fails.$$,
  $$Rounding noise creates false mismatches, and on large volumes the same effect can create real money discrepancies. Financial code should never use float for currency.$$,
  ARRAY[$$decimal$$, $$cents$$, $$integer$$],
  ARRAY[$$floating|float$$, $$precision$$, $$rounding$$, $$exactly$$]
);

SELECT seed_verification_text(
  'verification-it-12', 'IT / Software', $$The Missing Await$$,
  $$An Express endpoint returns a user's name. Requests for users that do not exist return 200 with an empty name instead of a 404. AI wrote the route.$$,
  'medium',
  ARRAY[
    $$app.get('/api/users/:id', async (req, res) => {$$,
    $$  const user = db.query($$,
    $$    'SELECT * FROM users WHERE id = $1', [req.params.id]);$$,
    $$  if (!user) {$$,
    $$    return res.status(404).json({ error: 'User not found' });$$,
    $$  }$$,
    $$  res.json({ name: user.name });$$,
    $$});$$
  ],
  ARRAY[2, 3],
  $$Lines 2 to 3. db.query is asynchronous but it is not awaited, so user is a Promise, not a result.$$,
  $$Await the call and check the rows: const { rows } = await db.query('SELECT * FROM users WHERE id = $1', [req.params.id]); if (rows.length === 0) return res.status(404)...; res.json({ name: rows[0].name });. A Promise is always truthy, so the 404 branch can never run, and user.name is undefined.$$,
  $$The endpoint appears to work for valid ids but fails silently for missing ones. Always check that every database or network call in an async function is awaited and that the result shape matches the library.$$,
  ARRAY[$$await$$, $$rows$$],
  ARRAY[$$promise$$, $$truthy$$, $$undefined$$, $$404$$, $$async$$]
);

SELECT seed_verification_text(
  'verification-it-13', 'IT / Software', $$The Forgeable Token$$,
  $$The VerifAI-style API protects its routes with a middleware that reads the bearer token. A tester shows that a hand-built token with someone else's user id is accepted. AI wrote the middleware.$$,
  'hard',
  ARRAY[
    $$const jwt = require('jsonwebtoken');$$,
    $$function requireAuth(req, res, next) {$$,
    $$  const token = (req.headers.authorization || '').replace('Bearer ', '');$$,
    $$  const payload = jwt.decode(token);$$,
    $$  if (!payload) return res.status(401).end();$$,
    $$  req.user = payload;$$,
    $$  next();$$,
    $$}$$
  ],
  ARRAY[4],
  $$Line 4. jwt.decode only reads the token. It does not check the signature, so anyone can craft a token.$$,
  $$Verify the signature: const payload = jwt.verify(token, process.env.JWT_SECRET); inside a try/catch that returns 401 on failure. In this stack, with Firebase Auth, verify the Firebase ID token with admin.auth().verifyIdToken(token) from the Firebase Admin SDK instead.$$,
  $$This is a complete authentication bypass: an attacker can impersonate any user, including an admin. Decoding is not verifying, and this mistake appears in real code reviews.$$,
  ARRAY[$$jwt.verify|verify$$, $$verifyidtoken$$, $$signature$$],
  ARRAY[$$forge$$, $$impersonate$$, $$decode$$, $$bypass$$, $$authentication$$]
);

SELECT seed_verification_text(
  'verification-it-14', 'IT / Software', $$The Open Attempt Endpoint$$,
  $$Authenticated users can fetch their own task attempts. A tester logs in as user A and fetches user B's attempt by changing the id in the URL. AI wrote the route.$$,
  'hard',
  ARRAY[
    $$// GET /api/attempts/:id   (requireAuth sets req.user.id)$$,
    $$router.get('/attempts/:id', requireAuth, async (req, res) => {$$,
    $$  const { rows } = await db.query($$,
    $$    'SELECT * FROM task_attempts WHERE id = $1',$$,
    $$    [req.params.id]);$$,
    $$  if (rows.length === 0) return res.status(404).end();$$,
    $$  res.json(rows[0]);$$,
    $$});$$
  ],
  ARRAY[4, 5],
  $$Lines 4 to 5. The query checks that a user is logged in but never checks that the attempt belongs to them.$$,
  $$Scope the query to the owner: 'SELECT * FROM task_attempts WHERE id = $1 AND user_id = $2', [req.params.id, req.user.id]. Return 404 if no row matches. Using non-guessable ids (UUIDs) helps but is not a replacement for the ownership check.$$,
  $$This is insecure direct object reference, a form of broken access control at the top of the OWASP list. A user can read any other user's data, which is a POPIA problem for any app that stores personal information.$$,
  ARRAY[$$user_id$$, $$req.user.id$$, $$ownership$$],
  ARRAY[$$idor$$, $$access control$$, $$another user$$, $$owasp$$, $$popia$$, $$enumerate$$]
);

SELECT seed_verification_text(
  'verification-it-15', 'IT / Software', $$The Double Spend$$,
  $$A rewards feature lets users redeem credit. A user with R100 credit sent two R80 redemptions at the same moment and both succeeded, leaving a balance of -R60. AI wrote the function.$$,
  'hard',
  ARRAY[
    $$async function redeem(userId, amount) {$$,
    $$  const { rows } = await db.query($$,
    $$    'SELECT balance FROM wallets WHERE user_id = $1', [userId]);$$,
    $$  if (rows[0].balance < amount) throw new Error('Insufficient funds');$$,
    $$  await db.query($$,
    $$    'UPDATE wallets SET balance = balance - $1 WHERE user_id = $2',$$,
    $$    [amount, userId]);$$,
    $$  return 'ok';$$,
    $$}$$
  ],
  ARRAY[3, 4, 5, 6, 7],
  $$Lines 3 to 7. The balance is read, checked in code, then updated in a separate statement, so two requests can both pass the check.$$,
  $$Make the check and the update one atomic statement: UPDATE wallets SET balance = balance - $1 WHERE user_id = $2 AND balance >= $1 and treat rowCount === 0 as insufficient funds. Alternatively use a transaction and SELECT ... FOR UPDATE to lock the row.$$,
  $$Race conditions only appear under concurrent load, so normal testing misses them. In a payments or rewards feature, the result is money or credit created from nothing.$$,
  ARRAY[$$atomic$$, $$for update$$, $$balance >=$$, $$transaction$$],
  ARRAY[$$race condition$$, $$concurrent$$, $$two requests$$, $$negative balance$$]
);
