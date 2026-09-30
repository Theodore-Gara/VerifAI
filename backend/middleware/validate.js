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

module.exports = { positiveIntegerParam, requiredString };
