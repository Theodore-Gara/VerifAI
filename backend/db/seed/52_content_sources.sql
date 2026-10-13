-- VerifAI AI Lab — confirmed content sources (licences checked 2026-10-12).
--
-- Re-check each work's licence on its own page before launch. Idempotent:
-- upserts by title.

INSERT INTO content_sources
  (title, author, publisher, edition, source_url, license, license_url, industry, checked_on, notes)
VALUES
  ('Corporate Finance', 'Kenneth S. Bigel', 'Open Touro', '2023',
   'https://touro.pressbooks.pub/corporatefinance/', 'CC_BY_4',
   'https://creativecommons.org/licenses/by/4.0/', 'FINANCE', '2026-10-12',
   'Verified on publisher pages; check individual figure captions for third-party items.'),
  ('Introduction to Financial Analysis', 'Kenneth S. Bigel', 'Open Touro', '2022',
   'https://touroscholar.touro.edu/opentextbooks/2/', 'CC_BY_4',
   'https://creativecommons.org/licenses/by/4.0/', 'FINANCE', '2026-10-12',
   NULL),
  ('Financial Management for Small Businesses', 'Lindon J. Robison',
   'Michigan State University Libraries', '2nd OER Edition',
   'https://openbooks.lib.msu.edu/financialmanagement/', 'CC_BY_4',
   'https://creativecommons.org/licenses/by/4.0/', 'FINANCE', '2026-10-12',
   NULL),
  ('South African legislation and court judgments',
   'Government of South Africa / Judiciary', NULL, NULL,
   'https://www.saflii.org', 'PUBLIC_DOMAIN',
   'https://libguides.wits.ac.za/LegalDeposit/Copyright', 'LEGAL', '2026-10-12',
   'Official text only: no copyright in official texts under s.12(8)(a) of the Copyright Act. Commentary, summaries and headnotes are still protected, so write original scenarios around the primary sources.'),
  ('NIST AI Risk Management Framework',
   'National Institute of Standards and Technology (NIST)', 'NIST', 'AI RMF 1.0',
   'https://www.nist.gov/itl/ai-risk-management-framework', 'PUBLIC_DOMAIN',
   'https://www.nist.gov/open', 'CROSS_INDUSTRY', '2026-10-12',
   'US federal government work, effectively public domain; third-party images/quotes inside may be protected.'),
  ('OWASP Cheat Sheet Series', 'OWASP Foundation', 'OWASP', NULL,
   'https://cheatsheetseries.owasp.org', 'CC_BY_SA_4',
   'https://creativecommons.org/licenses/by-sa/4.0/', 'IT_SOFTWARE', '2026-10-12',
   'Share-alike: use as linked reference or inspiration only; do not adapt text into lessons unless releasing it CC BY-SA.'),
  ('Dive into Deep Learning',
   'Aston Zhang, Zachary C. Lipton, Mu Li, Alexander J. Smola', NULL, NULL,
   'https://d2l.ai', 'CC_BY_SA_4',
   'https://creativecommons.org/licenses/by-sa/4.0/', 'IT_SOFTWARE', '2026-10-12',
   'Book text CC BY-SA 4.0 (code is separately MIT). Link/inspire only.')
ON CONFLICT (title) DO UPDATE SET
  author = EXCLUDED.author,
  publisher = EXCLUDED.publisher,
  edition = EXCLUDED.edition,
  source_url = EXCLUDED.source_url,
  license = EXCLUDED.license,
  license_url = EXCLUDED.license_url,
  industry = EXCLUDED.industry,
  checked_on = EXCLUDED.checked_on,
  notes = EXCLUDED.notes;
