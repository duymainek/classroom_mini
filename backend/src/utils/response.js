const _camelCase = (str) => {
  return str.replace(/[_-](\w)/g, (_, c) => (c ? c.toUpperCase() : ''))
            .replace(/^(\w)/, (c) => c.toLowerCase());
};

const isPlainObject = (value) => {
  return Object.prototype.toString.call(value) === '[object Object]';
};

const toCamelCase = (value) => {
  if (Array.isArray(value)) {
    return value.map((item) => toCamelCase(item));
  }
  if (isPlainObject(value)) {
    const result = {};
    for (const [key, val] of Object.entries(value)) {
      const newKey = _camelCase(key);
      result[newKey] = toCamelCase(val);
    }
    return result;
  }
  return value;
};

/**
 * Build a standard API response with consistent shape and camelCased data.
 * @param {boolean} success
 * @param {string} message
 * @param {any} data
 * @param {Object} [meta]
 * @returns {{success: boolean, message?: string, data?: any, meta?: Object}}
 */
const buildResponse = (success, message, data, meta) => {
  const response = { success };
  if (message) response.message = message;
  if (typeof data !== 'undefined') response.data = toCamelCase(data);
  if (meta) response.meta = toCamelCase(meta);
  return response;
};

module.exports = {
  toCamelCase,
  buildResponse
};


