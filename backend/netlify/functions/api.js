const serverless = require('serverless-http');
const app = require('../../server');

// Wrap Express app for Netlify Functions
const handler = serverless(app, {
  binary: false
});

module.exports = { handler };