const express = require('express');
const router  = express.Router();
const bcrypt  = require('bcrypt');
const jwt     = require('jsonwebtoken');
const crypto  = require('crypto');
const { v4: uuidv4 } = require('uuid');
const { query, pool } = require('../../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');
const { levelFromScore } = require('../utils/trust');
const { verifyNik, verifySim } = require('../utils/verify');

// Helper: terbitkan access token (15m) + refresh token (30d) dan simpan ke DB
async function issueTokenPair(payload) {
  const jti = uuidv4();
  const accessToken  = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '15m' });
  const refreshToken = jwt.sign({ ...payload, jti }, process.env.REFRESH_SECRET, { expiresIn: '30d' });
  const expiresAt    = new Date(Date.now() + 30 * 24 * 3600 * 1000);

  const userId   = payload.role === 'user'   ? payload.userId   : null;
  const vendorId = payload.role === 'vendor' ? payload.vendorId : null;

  await query(
    'INSERT INTO refresh_tokens (jti, user_id, vendor_id, expires_at) VALUES (?,?,?,?)',
    [jti, userId, vendorId, expiresAt]
  );

  return { accessToken, refreshToken };
}

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const { nama, email, phone, password, nik, nomor_sim } = req.body;
    if (!nama || !email || !password || !nik || !nomor_sim)
      return res.status(400).json({ success: false, message: 'Semua field wajib diisi' });

    const existing = await query('SELECT user_id FROM users WHERE email=?', [email]);
    if (existing.length > 0)
      return res.status(409).json({ success: false, message: 'Email sudah terdaftar' });

    // Verifikasi NIK via tabel Dukcapil
    const dukcapilResult = await verifyNik(nik);
    if (!dukcapilResult.valid)
      return res.status(400).json({ success: false, message: 'NIK tidak ditemukan atau format tidak valid', data: { step: 'dukcapil', reason: dukcapilResult.reason } });

    // Verifikasi SIM via tabel Korlantas
    const korlantasResult = await verifySim(nomor_sim);
    if (!korlantasResult.valid)
      return res.status(400).json({ success: false, message: 'SIM tidak aktif atau tidak ditemukan', data: { step: 'korlantas', reason: korlantasResult.reason } });

    const nama_lengkap = dukcapilResult.nama_lengkap;

    const passwordHash = await bcrypt.hash(password, 10);
    const nikHash = crypto.createHash('sha256').update(nik).digest('hex');
    const userId = uuidv4();

    const delta    = parseInt(process.env.TRUST_SCORE_VERIFY || 20);
    const newScore = Math.min(100, delta);
    const level    = levelFromScore(newScore);

    await conn.beginTransaction();

    await conn.execute(
      `INSERT INTO users (user_id, nama, nama_lengkap, email, phone, password_hash, nik, nik_hash, nomor_sim,
                          status_verifikasi, verifikasi_at, trust_score, level_trust, saldo_ewallet)
       VALUES (?,?,?,?,?,?,?,?,?,'verified',NOW(),?,?,0)`,
      [userId, nama, nama_lengkap, email, phone || null, passwordHash, nik, nikHash, nomor_sim, newScore, level]
    );

    // Buat akun ewallet default agar user dapat langsung top up dan booking
    const ewalletMethods = ['gopay', 'ovo', 'dana'];
    for (const metode of ewalletMethods) {
      await conn.execute(
        'INSERT INTO ewallet_accounts (account_id, user_id, metode_bayar, saldo) VALUES (?,?,?,0)',
        [uuidv4(), userId, metode]
      );
    }

    await conn.execute(
      `INSERT INTO trust_logs (user_id, parameter, delta_skor, skor_sebelum, skor_sesudah, keterangan)
       VALUES (?,'verifikasi_identitas',?,0,?,?)`,
      [userId, delta, newScore, 'Verifikasi NIK dan SIM C saat registrasi']
    );

    await conn.commit();

    res.status(201).json({
      success: true,
      message: 'Registrasi berhasil. Identitas telah terverifikasi.',
      data: { user_id: userId, nama, nama_lengkap, email, verified: true, trust_score: newScore, level_trust: level }
    });
  } catch (err) {
    await conn.rollback().catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  } finally {
    conn.release();
  }
});

// POST /api/auth/login - Login penyewa
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ success: false, message: 'Email dan password wajib diisi' });

    const rows = await query(
      `SELECT user_id, nama, nama_lengkap, email, password_hash, trust_score, level_trust,
              status_verifikasi, saldo_ewallet, is_active
       FROM users WHERE email=?`, [email]
    );
    if (rows.length === 0)
      return res.status(401).json({ success: false, message: 'Email atau password salah' });

    const user = rows[0];
    if (!user.is_active)
      return res.status(403).json({ success: false, message: 'Akun tidak aktif' });

    let valid = false;
    try { valid = await bcrypt.compare(password, user.password_hash); } catch { valid = false; }

    // Fallback untuk demo: jika hash lama tidak valid, cek password langsung
    if (!valid && process.env.NODE_ENV === 'development') {
      const demoPw = ['user@123', 'demo1234'];
      if (demoPw.includes(password)) {
        const newHash = await bcrypt.hash(password, 10);
        await query('UPDATE users SET password_hash=? WHERE user_id=?', [newHash, user.user_id]);
        valid = true;
      }
    }

    if (!valid)
      return res.status(401).json({ success: false, message: 'Email atau password salah' });

    const payload = { userId: user.user_id, nama: user.nama, role: 'user' };
    const { accessToken, refreshToken } = await issueTokenPair(payload);

    const { password_hash, ...userData } = user;
    res.json({
      success: true,
      message: 'Login berhasil',
      data: { user: userData, access_token: accessToken, refresh_token: refreshToken }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/auth/login-vendor
router.post('/login-vendor', async (req, res) => {
  try {
    const { email, password } = req.body;
    const rows = await query(
      `SELECT vendor_id, nama_vendor, kontak_email, password_hash, status_aktif, status_langganan
       FROM vendors WHERE kontak_email=?`, [email]
    );
    if (rows.length === 0)
      return res.status(401).json({ success: false, message: 'Email atau password salah' });

    const vendor = rows[0];
    if (!vendor.status_aktif)
      return res.status(403).json({ success: false, message: 'Akun vendor tidak aktif' });

    let valid = false;
    try { valid = await bcrypt.compare(password, vendor.password_hash); } catch { valid = false; }

    // Fallback demo
    if (!valid && process.env.NODE_ENV === 'development' && password === 'vendor@123') {
      const newHash = await bcrypt.hash(password, 10);
      await query('UPDATE vendors SET password_hash=? WHERE vendor_id=?', [newHash, vendor.vendor_id]);
      valid = true;
    }

    if (!valid)
      return res.status(401).json({ success: false, message: 'Email atau password salah' });

    const payload = { vendorId: vendor.vendor_id, namaVendor: vendor.nama_vendor, role: 'vendor' };
    const { accessToken, refreshToken } = await issueTokenPair(payload);

    const { password_hash, ...vendorData } = vendor;
    res.json({
      success: true,
      message: 'Login vendor berhasil',
      data: { vendor: vendorData, access_token: accessToken, refresh_token: refreshToken }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/auth/refresh
router.post('/refresh', async (req, res) => {
  try {
    const { refresh_token } = req.body;
    if (!refresh_token)
      return res.status(400).json({ success: false, message: 'refresh_token diperlukan' });

    let decoded;
    try {
      decoded = jwt.verify(refresh_token, process.env.REFRESH_SECRET);
    } catch {
      return res.status(401).json({ success: false, message: 'Token tidak valid' });
    }

    const rows = await query('SELECT * FROM refresh_tokens WHERE jti=? AND revoked=0', [decoded.jti]);
    if (!rows[0] || new Date(rows[0].expires_at) < new Date())
      return res.status(401).json({ success: false, message: 'Token kedaluwarsa atau sudah dipakai' });

    await query('UPDATE refresh_tokens SET revoked=1 WHERE jti=?', [decoded.jti]);

    const payload = decoded.role === 'vendor'
      ? { vendorId: decoded.vendorId, namaVendor: decoded.namaVendor, role: 'vendor' }
      : { userId: decoded.userId, nama: decoded.nama, role: 'user' };

    const { accessToken, refreshToken: newRefresh } = await issueTokenPair(payload);

    res.json({ success: true, data: { access_token: accessToken, refresh_token: newRefresh } });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/auth/logout
router.post('/logout', async (req, res) => {
  const { refresh_token } = req.body;
  if (refresh_token) {
    try {
      const decoded = jwt.verify(refresh_token, process.env.REFRESH_SECRET);
      await query('UPDATE refresh_tokens SET revoked=1 WHERE jti=?', [decoded.jti]);
    } catch { /* token invalid, abaikan */ }
  }
  res.json({ success: true, message: 'Logout berhasil' });
});

// POST /api/auth/verify-identity - Verifikasi identitas via tabel Dukcapil & Korlantas
router.post('/verify-identity', authMiddleware, async (req, res) => {
  try {
    const { nik, nomor_sim } = req.body;
    const userId = req.user.userId;

    if (!nik || !nomor_sim)
      return res.status(400).json({ success: false, message: 'NIK dan nomor SIM diperlukan' });

    if (req.user.role !== 'user')
      return res.status(403).json({ success: false, message: 'Hanya penyewa yang dapat melakukan verifikasi identitas' });

    // Verifikasi NIK ke tabel dukcapil_datadiri
    if (!/^\d{16}$/.test(nik)) {
      return res.json({
        success: false, status: 'rejected',
        message: 'Format NIK tidak valid',
        data: { step: 'dukcapil', reason: 'format_invalid' }
      });
    }

    const dukcapilRows = await query(
      'SELECT nama_lengkap, tanggal_lahir FROM dukcapil_datadiri WHERE nik=?', [nik]
    );
    if (dukcapilRows.length === 0) {
      await query(
        `INSERT INTO trust_logs (user_id, parameter, delta_skor, skor_sebelum, skor_sesudah, keterangan)
         SELECT user_id, 'verification_failed', 0, trust_score, trust_score, 'NIK tidak ditemukan di Dukcapil'
         FROM users WHERE user_id=?`,
        [userId]
      );
      return res.json({
        success: false, status: 'rejected',
        message: 'NIK tidak ditemukan di database Dukcapil',
        data: { step: 'dukcapil', reason: 'not_found' }
      });
    }

    const { nama_lengkap, tanggal_lahir } = dukcapilRows[0];

    // Verifikasi SIM C ke tabel korlantas_sim
    const simRows = await query(
      'SELECT jenis_sim, tanggal_berlaku, status_aktif FROM korlantas_sim WHERE nomor_sim=?', [nomor_sim]
    );
    if (simRows.length === 0 || !simRows[0].status_aktif) {
      await query(
        `INSERT INTO trust_logs (user_id, parameter, delta_skor, skor_sebelum, skor_sesudah, keterangan)
         SELECT user_id, 'verification_failed', 0, trust_score, trust_score, 'SIM tidak aktif atau tidak ditemukan'
         FROM users WHERE user_id=?`,
        [userId]
      );
      return res.json({
        success: false, status: 'rejected',
        message: 'SIM tidak aktif atau tidak ditemukan di Korlantas',
        data: { step: 'korlantas', reason: 'expired' }
      });
    }

    if (simRows[0].jenis_sim !== 'C') {
      return res.json({
        success: false, status: 'rejected',
        message: 'Hanya SIM C yang diterima untuk sewa motor',
        data: { step: 'korlantas', reason: 'wrong_sim_type' }
      });
    }

    const sim = simRows[0];
    const nikHash = crypto.createHash('sha256').update(nik).digest('hex');
    const userRows = await query('SELECT status_verifikasi, trust_score FROM users WHERE user_id=?', [userId]);
    if (userRows.length === 0)
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });

    const user = userRows[0];
    let newScore = user.trust_score;
    let delta = 0;

    if (user.status_verifikasi !== 'verified') {
      delta = parseInt(process.env.TRUST_SCORE_VERIFY || 20);
      newScore = Math.min(100, newScore + delta);
      const level = levelFromScore(newScore);

      await query(
        `UPDATE users SET status_verifikasi='verified', verifikasi_at=NOW(),
         nik=?, nik_hash=?, nama_lengkap=?, nomor_sim=?, trust_score=?, level_trust=? WHERE user_id=?`,
        [nik, nikHash, nama_lengkap, nomor_sim, newScore, level, userId]
      );
      await query(
        `INSERT INTO trust_logs (user_id, parameter, delta_skor, skor_sebelum, skor_sesudah, keterangan)
         VALUES (?,'verifikasi_identitas',?,?,?,?)`,
        [userId, delta, user.trust_score, newScore, 'NIK dan SIM C terverifikasi via database Dukcapil dan Korlantas']
      );
    }

    res.json({
      success: true, status: 'verified',
      message: 'Identitas berhasil diverifikasi',
      data: {
        nik_valid: true,
        sim_valid: true,
        nama_lengkap,
        sim_berlaku_hingga: sim.tanggal_berlaku,
        trust_score: newScore,
        level_trust: levelFromScore(newScore),
        delta: delta > 0 ? `+${delta} poin verifikasi identitas` : 'Sudah terverifikasi sebelumnya',
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
