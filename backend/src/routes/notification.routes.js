// notification.routes.js
const express = require('express');
const r = express.Router();
const { query } = require('../../config/database');
const { authMiddleware, vendorMiddleware } = require('../middleware/auth.middleware');

r.get('/', authMiddleware, async (req, res) => {
  try {
    const rows = await query(
      'SELECT * FROM notifications WHERE user_id=? ORDER BY created_at DESC LIMIT 20', [req.user.userId]
    );
    res.json({ success: true, data: rows, unread_count: rows.filter(n => !n.is_read).length });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

r.patch('/read-all', authMiddleware, async (req, res) => {
  try {
    await query('UPDATE notifications SET is_read=1 WHERE user_id=?', [req.user.userId]);
    res.json({ success: true, message: 'Semua notifikasi dibaca' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

r.get('/vendor', vendorMiddleware, async (req, res) => {
  try {
    const rows = await query(
      'SELECT * FROM notifications WHERE vendor_id=? ORDER BY created_at DESC LIMIT 20', [req.vendor.vendorId]
    );
    res.json({ success: true, data: rows, unread_count: rows.filter(n => !n.is_read).length });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// Fase 9: per-id read
r.patch('/:id/read', authMiddleware, async (req, res) => {
  try {
    await query('UPDATE notifications SET is_read=1 WHERE notif_id=? AND user_id=?', [req.params.id, req.user.userId]);
    res.json({ success: true, message: 'Notifikasi ditandai sudah dibaca' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

r.patch('/vendor/:id/read', vendorMiddleware, async (req, res) => {
  try {
    await query('UPDATE notifications SET is_read=1 WHERE notif_id=? AND vendor_id=?', [req.params.id, req.vendor.vendorId]);
    res.json({ success: true, message: 'Notifikasi ditandai sudah dibaca' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = r;
