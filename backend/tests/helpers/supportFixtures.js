// Shared rows for the support API tests (pool.query is mocked, as in the rest
// of the suite). Timestamps are fixed so versions and ETags are deterministic.
const T1 = new Date('2026-10-22T00:00:00Z');
const T2 = new Date('2026-10-25T09:30:00Z');

const HELP = [
  { id: 1, slug: 'what-is-verifai', title: 'What VerifAI is', summary: 'Intro', body_md: '## Hi\nVerifAI intro.', category: 'start', audience: 'all', sort_order: 10, updated_at: T1 },
  { id: 2, slug: 'troubleshooting', title: 'Troubleshooting', summary: 'Fixes', body_md: 'Cannot log in? Reset your password.', category: 'troubleshooting', audience: 'all', sort_order: 100, updated_at: T2 },
  { id: 3, slug: 'getting-around-the-app', title: 'Getting around', summary: 'Nav', body_md: 'Use the bottom bar.', category: 'start', audience: 'all', sort_order: 20, updated_at: T1 },
];

const FAQS = [
  { id: 1, slug: 'how-do-i-change-my-industry', question: 'How do I change my industry?', answer_md: 'Tap the industry label on Home.', topic: 'industry', sort_order: 20, updated_at: T1 },
  { id: 2, slug: 'what-is-verification-studio', question: 'What is Verification Studio?', answer_md: 'It checks your own material.', topic: 'verification', sort_order: 50, updated_at: T1 },
  { id: 3, slug: 'what-does-the-readiness-score-mean', question: 'What does the readiness score mean?', answer_md: 'A score from 0 to 100.', topic: 'progress', sort_order: 70, updated_at: T1 },
];

const GUIDES = [
  {
    id: 1, track_id: 1, track_name: 'Finance', slug: 'finance', tagline: 'Check numbers.',
    overview_md: 'Overview.', outcomes: { who_for: 'Students', by_the_end: ['a'] },
    feature_tour: [{ key: 'skills', title: 'Skills', items: [] }],
    how_to: { first_session: [], common_mistakes: [], related_faqs: ['how-do-i-change-my-industry', 'missing-faq'] },
    hero_image: 'guide-finance-hero', body_image: 'guide-finance-body', updated_at: T1,
  },
  {
    id: 2, track_id: 2, track_name: 'Legal', slug: 'legal', tagline: 'Check citations.',
    overview_md: 'Overview.', outcomes: {}, feature_tour: [], how_to: { related_faqs: [] },
    hero_image: 'guide-legal-hero', body_image: 'guide-legal-body', updated_at: T1,
  },
];

const TOURS = [
  { tour_key: 'global-v1', track_id: null, title: 'VerifAI in 60 seconds', updated_at: T1,
    steps: [{ id: 'dashboard', title: 'Home', body_md: 'Transcript.', media: null }] },
  { tour_key: 'finance-v1', track_id: 1, title: 'Finance', updated_at: T2,
    steps: [{ id: 'skills', title: 'Skills', body_md: 'Transcript.', media: null }] },
  { tour_key: 'legal-v1', track_id: 2, title: 'Legal', updated_at: T1,
    steps: [{ id: 'skills', title: 'Skills', body_md: 'Transcript.', media: { kind: 'video', url: 'https://cdn.example/legal.mp4', captions_url: 'https://cdn.example/legal.vtt', poster: 'https://cdn.example/legal.jpg', duration_seconds: 40 } }] },
];

const ABOUT = {
  slug: 'about', title: 'About VerifAI', updated_at: T1,
  data: { mission_md: 'Mission.', vision_md: 'Vision.', south_africa_md: 'SA.', how_it_helps_md: 'Helps.', who_for_md: 'Who.', how_it_works: [] },
};

// Answers the content queries the support service issues; returns undefined for
// anything else so a test can layer its own handlers on top.
function contentRows(s) {
  if (s.includes('FROM help_articles') && s.includes('published = TRUE')) return { rows: HELP };
  if (s.includes('FROM faqs') && s.includes('published = TRUE')) return { rows: FAQS };
  if (s.includes('FROM industry_guides g')) return { rows: GUIDES };
  if (s.includes('FROM support_tours')) return { rows: TOURS };
  if (s.includes('FROM support_pages')) return { rows: [ABOUT] };
  return undefined;
}

module.exports = { HELP, FAQS, GUIDES, TOURS, ABOUT, T1, T2, contentRows };
