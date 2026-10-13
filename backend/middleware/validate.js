function positiveIntegerParam(value, field = 'id') {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    const error = new Error(`${field} must be a positive integer.`);
    error.status = 400;
    throw error;
  }
  return parsed;
}

function requiredString(value, field, maxLength = 5000) {
  if (typeof value !== 'string' || !value.trim()) {
    const error = new Error(`${field} is required.`);
    error.status = 400;
    throw error;
  }
  if (value.trim().length > maxLength) {
    const error = new Error(`${field} must be ${maxLength} characters or fewer.`);
    error.status = 400;
    throw error;
  }
  return value.trim();
}

// Returns undefined when absent, otherwise a trimmed non-empty string within
// the limit (404-style fields). Throws 400 when present but malformed.
function optionalString(value, field, maxLength = 5000) {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== 'string' || !value.trim()) {
    const error = new Error(`${field} must be a non-empty string.`);
    error.status = 400;
    throw error;
  }
  if (value.trim().length > maxLength) {
    const error = new Error(`${field} must be ${maxLength} characters or fewer.`);
    error.status = 400;
    throw error;
  }
  return value.trim();
}

// Clamps an integer query/body value into [min, max], falling back when absent
// or unparseable.
function clampInt(value, fallback, min, max) {
  const parsed = Number.parseInt(value, 10);
  if (!Number.isInteger(parsed)) return fallback;
  return Math.min(max, Math.max(min, parsed));
}

module.exports = { positiveIntegerParam, requiredString, optionalString, clampInt };

