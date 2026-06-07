const express = require('express');
const router = express.Router();
const { pool, query } = require('../../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');
const { credit } = require('../utils/wallet');

// POST /api/ewallet/topup
router.post('/topup', authMiddleware, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const { metode_bayar, amount } = req.body;
    const user_id = req.user.userId;
    if (!metode_bayar || !amount || parseFloat(amount) <= 0)
      return res.status(400).json({ success: false, message: 'metode_bayar dan amount > 0 wajib diisi' });

    const [rows] = await conn.execute(
      'SELECT account_id FROM ewallet_accounts WHERE user_id=? AND metode_bayar=?',
      [user_id, metode_bayar]
    );
    if (!rows[0]) {
      await conn.rollback();
      return res.status(404).json({ success: false, message: `Metode ${metode_bayar} tidak terdaftar` });
    }

    const saldoBaru = await credit(conn, {
      userId: user_id, metodeBayar: metode_bayar, amount: parseFloat(amount),
      keterangan: 'Top-up via app', tipe: 'topup',
    });
    await conn.commit();
    res.json({ success: true, message: 'Top-up berhasil', data: { saldo_baru: saldoBaru } });
  } catch (err) {
    await conn.rollback().catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  } finally {
    conn.release();
  }
});

// GET /api/ewallet/transactions?metode_bayar=gopay
router.get('/transactions', authMiddleware, async (req, res) => {
  try {
    const { metode_bayar } = req.query;
    let sql = `SELECT et.txn_id, et.tipe, et.amount, et.saldo_sebelum, et.saldo_sesudah,
                      et.keterangan, et.ref_booking_id, et.created_at, ea.metode_bayar
               FROM ewallet_transactions et
               JOIN ewallet_accounts ea ON et.account_id = ea.account_id
               WHERE ea.user_id = ?`;
    const params = [req.user.userId];
    if (metode_bayar) { sql += ' AND ea.metode_bayar = ?'; params.push(metode_bayar); }
    sql += ' ORDER BY et.created_at DESC LIMIT 50';
    const rows = await query(sql, params);
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;
