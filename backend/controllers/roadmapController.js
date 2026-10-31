const { getRoadmap } = require('../services/roadmapService');
const { positiveIntegerParam } = require('../middleware/validate');

// GET /api/roadmap[?track=<id>]
// The signed-in learner's milestone tracker for their active industry, or for
// another track when previewing (?track=). One call: the response is derived
// from a fixed number of batched queries, never one per milestone.
async function getRoadmapHandler(req, res, next) {
  try {
    const user = req.user;
    let trackId = user.industry_track_id;

    if (req.query.track !== undefined) {
      try {
        trackId = positiveIntegerParam(req.query.track, 'track');
      } catch (err) {
        return res.status(400).json({ error: err.message, code: 'invalid_track', request_id: req.requestId });
      }
    }
    if (!trackId) {
      return res.status(400).json({
        error: 'Choose an industry first.',
        code: 'track_required',
        request_id: req.requestId,
      });
    }

    const roadmap = await getRoadmap({
      userId: user.id,
      trackId,
      activeTrackId: user.industry_track_id,
    });
    if (!roadmap) {
      return res.status(404).json({ error: 'Industry not found.', code: 'track_not_found', request_id: req.requestId });
    }

    // Personal and always live: derived from the learner's latest work.
    res.setHeader('Cache-Control', 'private, no-store');
    return res.status(200).json({ ...roadmap, request_id: req.requestId });
  } catch (err) {
    return next(err);
  }
}

module.exports = { getRoadmap: getRoadmapHandler };
