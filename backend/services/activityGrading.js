// Grades AI Lab practice activities server-side. The answer key lives in
// lab_activities.correct and is never sent to the app.
//
// Response shape by type:
//   multiple_choice -> integer option index
//   true_false      -> boolean
//   fill_blank      -> string
//   matching        -> object { left: right, ... }
//   ordering        -> array of items in the chosen order
const TYPES = new Set(['multiple_choice', 'true_false', 'matching', 'fill_blank', 'ordering']);

function normalize(value) {
  return String(value == null ? '' : value).trim().toLowerCase();
}

function gradeActivity(type, correct, response) {
  if (!TYPES.has(type)) {
    const error = new Error('This activity type is not supported.');
    error.status = 422;
    throw error;
  }

  switch (type) {
    case 'multiple_choice':
      return Number.isInteger(response) && Number(response) === Number(correct.answer_index);
    case 'true_false':
      return typeof response === 'boolean' && response === correct.answer;
    case 'fill_blank': {
      const accepted = Array.isArray(correct.accepted) ? correct.accepted : [];
      const answer = normalize(response);
      return answer.length > 0 && accepted.some((option) => normalize(option) === answer);
    }
    case 'matching': {
      const mapping = correct.mapping || {};
      const keys = Object.keys(mapping);
      if (!response || typeof response !== 'object' || Array.isArray(response)) return false;
      return keys.length > 0 && keys.every((key) => response[key] === mapping[key]);
    }
    case 'ordering': {
      const order = Array.isArray(correct.order) ? correct.order : [];
      if (!Array.isArray(response) || response.length !== order.length) return false;
      return order.every((item, index) => response[index] === item);
    }
    default:
      return false;
  }
}

module.exports = { gradeActivity, normalize, TYPES };
