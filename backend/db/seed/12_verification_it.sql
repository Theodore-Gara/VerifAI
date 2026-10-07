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
