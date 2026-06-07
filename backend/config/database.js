const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : '.env';
dotenv.config({ path: envFile });

const pool = mysql.createPool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT) || 3306,
  database: process.env.DB_NAME     || 'renthub_db',
  user:     process.env.DB_USER     || 'root',
  password: process.env.DB_PASSWORD || '',
  waitForConnections: true,
  connectionLimit: 20,
  queueLimit: 0,
  timezone: '+07:00',
});

// Test koneksi saat startup (dilewati saat test: pool tetap connect lazy saat
// query pertama, dan koneksi eager bisa hidup melewati unit test sinkron lalu
// crash saat teardown)
if (process.env.NODE_ENV !== 'test') {
  (async () => {
    try {
      const conn = await pool.getConnection();
      const [rows] = await conn.query('SELECT NOW() as now');
      console.log('✅ MySQL connected:', rows[0].now);
      conn.release();
    } catch (err) {
      console.error('❌ MySQL connection failed:', err.message);
      console.error('   Pastikan XAMPP MySQL sudah dijalankan!');
    }
  })();
}

// Helper: query dengan promise
const query = async (sql, params = []) => {
  const [rows] = await pool.execute(sql, params);
  return rows;
};

module.exports = { pool, query };
