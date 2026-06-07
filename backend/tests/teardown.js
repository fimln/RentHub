const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env.test') });

module.exports = async () => {
  try {
    const { pool } = require('../config/database');
    await pool.end();
  } catch (_) {}
};
