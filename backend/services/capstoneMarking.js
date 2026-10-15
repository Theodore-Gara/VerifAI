// Marks capstone questions. Auto types return awarded marks; rubric questions
// return { pending: true } so the attempt is held for a reviewer (or an AI
// marker with a human spot-check) before it is finalised.
//
// Response shapes follow the practice activities, plus:
//   numeric      -> number (or array of numbers when the question has parts)
//   multi_select -> array of selected option indices
//   extended_response -> free text (always rubric-marked)

function normalize(value) {
  return String(value == null ? '' : value).trim().toLowerCase();
}

function withinTolerance(response, answer, tolerance) {
  const r = Number(response);
  if (!Number.isFinite(r)) return false;
  return Math.abs(r - Number(answer)) <= (Number(tolerance) || 0);
}

function markNumeric(correct, response, max) {
  if (Array.isArray(correct.parts)) {
    let awarded = 0;
    correct.parts.forEach((part, index) => {
      const value = Array.isArray(response) ? response[index] : undefined;
      if (value !== undefined && value !== null && value !== '' && withinTolerance(value, part.answer, part.tolerance)) {
        awarded += Number(part.marks) || 0;
      }
    });
    return { awarded: Math.min(awarded, max), max, pending: false };
  }
  const ok = withinTolerance(response, correct.answer, correct.tolerance);
  return { awarded: ok ? max : 0, max, pending: false };
}

function markQuestion(question, response) {
  const max = Number(question.marks) || 0;
  if (question.marking === 'rubric' || question.type === 'extended_response') {
    return { awarded: null, max, pending: true };
  }

  const correct = question.correct || {};
  switch (question.type) {
    case 'multiple_choice':
      return { awarded: Number(response) === Number(correct.answer_index) ? max : 0, max, pending: false };
    case 'true_false':
      return { awarded: response === correct.answer ? max : 0, max, pending: false };
    case 'fill_blank': {
      const accepted = Array.isArray(correct.accepted) ? correct.accepted : [];
      const answer = normalize(response);
      const ok = answer.length > 0 && accepted.some((option) => normalize(option) === answer);
      return { awarded: ok ? max : 0, max, pending: false };
    }
    case 'matching': {
      const mapping = correct.mapping || {};
      const keys = Object.keys(mapping);
      if (!keys.length) return { awarded: 0, max, pending: false };
      const answered = response && typeof response === 'object' && !Array.isArray(response) ? response : {};
      // Partial credit per correct pair (a 5-pair matching is worth its 5 marks).
      const matched = keys.filter((key) => answered[key] === mapping[key]).length;
      return { awarded: Math.min(max, Math.round((max * matched) / keys.length)), max, pending: false };
    }
    case 'ordering': {
      const order = Array.isArray(correct.order) ? correct.order : [];
      const ok = Array.isArray(response) && response.length === order.length && order.every((v, i) => response[i] === v);
      return { awarded: ok ? max : 0, max, pending: false };
    }
    case 'numeric':
      return markNumeric(correct, response, max);
    case 'multi_select': {
      const indices = Array.isArray(correct.indices) ? correct.indices : [];
      const chosen = Array.isArray(response) ? response.map(Number) : [];
      const correctPicks = chosen.filter((i) => indices.includes(i)).length;
      const wrongPicks = chosen.filter((i) => !indices.includes(i)).length;
      const awarded = Math.max(0, Math.min(max, 2 * correctPicks - wrongPicks));
      return { awarded, max, pending: false };
    }
    default:
      return { awarded: 0, max, pending: false };
  }
}

// A rubric question is worth the sum of its criteria, capped at the question
// marks. `assigned` may be a single total or one mark per criterion.
function rubricAward(question, assigned) {
  const max = Number(question.marks) || 0;
  if (assigned === null || assigned === undefined) return 0;
  const total = Array.isArray(assigned)
    ? assigned.reduce((sum, mark) => sum + (Number(mark) || 0), 0)
    : Number(assigned) || 0;
  return Math.max(0, Math.min(max, Math.round(total)));
}

module.exports = { markQuestion, rubricAward, normalize };
