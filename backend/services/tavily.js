// Web search via Tavily, used by the Verification Studio and by Vera when a
// learner asks her to verify something. Degrades gracefully: with no key or on
// any error it returns an empty list rather than failing the request.
const TAVILY_URL = 'https://api.tavily.com/search';

async function webSearch(query, { maxResults = 5, fetchImpl = fetch } = {}) {
  const key = process.env.TAVILY_API_KEY;
  const text = String(query == null ? '' : query).trim();
  if (!key || !text) return [];

  try {
    const response = await fetchImpl(TAVILY_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${key}` },
      body: JSON.stringify({
        query: text.slice(0, 380),
        max_results: Math.min(8, Math.max(1, maxResults)),
        search_depth: 'advanced',
      }),
      signal: AbortSignal.timeout(15000),
    });
    if (!response.ok) return [];
    const data = await response.json();
    return (data.results || [])
      .filter((r) => r && r.url)
      .map((r) => ({
        title: String(r.title || r.url).slice(0, 200),
        url: String(r.url).slice(0, 500),
        content: String(r.content || '').replace(/\s+/g, ' ').slice(0, 500),
      }));
  } catch {
    return [];
  }
}

module.exports = { webSearch };
