// ============================================================
// payment.routes.js - read-only payment lookup
// Capture/refund/deduct ditangani di booking.routes via wallet.js
// ============================================================
const express = require('express');
const router  = express.Router();
const { query } = require('../../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');

router.get('/:booking_id', authMiddleware, async (req, res) => {
  try {
    const rows = await query(
      'SELECT p.*, b.user_id FROM payments p JOIN bookings b ON p.booking_id=b.booking_id WHERE p.booking_id=?',
      [req.params.booking_id]
    );
    if (!rows[0]) return res.status(404).json({ success: false, message: 'Pembayaran tidak ditemukan' });
    if (rows[0].user_id !== req.user.userId) return res.status(403).json({ success: false, message: 'Akses ditolak' });
    res.json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
