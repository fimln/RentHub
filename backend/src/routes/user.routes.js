// user.routes.js
const express = require('express');
const r = express.Router();
const { query } = require('../../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');

r.get('/profile', authMiddleware, async (req, res) => {
  try {
    const rows = await query(
      `SELECT u.user_id, u.nama, u.nama_lengkap, u.email, u.phone, u.status_verifikasi,
              u.trust_score, u.level_trust, u.verifikasi_at, u.created_at, u.foto_profil_url,
              COALESCE((SELECT SUM(saldo) FROM ewallet_accounts WHERE user_id=u.user_id), 0) AS saldo_ewallet
       FROM users u
       WHERE u.user_id=?`, [req.user.userId]
    );
    if (!rows[0]) return res.status(404).json({ success: false, message: 'User tidak ditemukan' });

    const accounts = await query(
      'SELECT account_id, metode_bayar, saldo FROM ewallet_accounts WHERE user_id=? ORDER BY metode_bayar',
      [req.user.userId]
    );

    res.json({ success: true, data: { ...rows[0], ewallet_accounts: accounts } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

r.put('/profile', authMiddleware, async (req, res) => {
  try {
    const { nama, email, phone, foto_profil_url } = req.body;
    const userId = req.user.userId;

    if (email) {
      const existing = await query('SELECT user_id FROM users WHERE email=? AND user_id!=?', [email, userId]);
      if (existing.length > 0)
        return res.status(409).json({ success: false, message: 'Email sudah digunakan akun lain' });
    }

    const updates = [];
    const values = [];
    if (nama !== undefined) { updates.push('nama=?'); values.push(nama); }
    if (email !== undefined) { updates.push('email=?'); values.push(email); }
    if (phone !== undefined) { updates.push('phone=?'); values.push(phone); }
    if (foto_profil_url !== undefined) { updates.push('foto_profil_url=?'); values.push(foto_profil_url); }

    if (updates.length === 0)
      return res.status(400).json({ success: false, message: 'Tidak ada field yang diupdate' });

    values.push(userId);
    await query(`UPDATE users SET ${updates.join(', ')} WHERE user_id=?`, values);

    const rows = await query(
      `SELECT u.user_id, u.nama, u.nama_lengkap, u.email, u.phone, u.status_verifikasi,
              u.trust_score, u.level_trust, u.foto_profil_url,
              COALESCE((SELECT SUM(saldo) FROM ewallet_accounts WHERE user_id=u.user_id), 0) AS saldo_ewallet
       FROM users u
       WHERE u.user_id=?`,
      [userId]
    );
    if (!rows[0]) return res.status(404).json({ success: false, message: 'User tidak ditemukan' });

    const accounts = await query(
      'SELECT account_id, metode_bayar, saldo FROM ewallet_accounts WHERE user_id=?',
      [userId]
    );

    res.json({ success: true, message: 'Profil berhasil diperbarui', data: { ...rows[0], ewallet_accounts: accounts } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

r.get('/trust-history', authMiddleware, async (req, res) => {
  try {
    const rows = await query(
      'SELECT * FROM trust_logs WHERE user_id=? ORDER BY created_at DESC LIMIT 20', [req.user.userId]
    );
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = r;
