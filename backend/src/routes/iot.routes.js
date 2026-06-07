// ============================================================
// iot.routes.js
// ============================================================
const express = require('express');
const r1 = express.Router();
const { v4: uuidv4 } = require('uuid');
const { query } = require('../../config/database');
const { authMiddleware, vendorMiddleware } = require('../middleware/auth.middleware');

r1.post('/unlock', authMiddleware, async (req, res) => {
  try {
    const { booking_id, aksi, unlock_token } = req.body;
    const rows = await query(
      `SELECT b.booking_id, b.vehicle_id, b.status_booking, b.user_id, b.unlock_token, p.status_payment
       FROM bookings b LEFT JOIN payments p ON b.booking_id=p.booking_id WHERE b.booking_id=?`, [booking_id]
    );
    const booking = rows[0];
    if (!booking) return res.status(404).json({ success: false, message: 'Booking tidak ditemukan' });
    if (booking.user_id !== req.user.userId) return res.status(403).json({ success: false, message: 'Akses ditolak' });
    if (booking.status_booking !== 'active') return res.status(400).json({ success: false, message: 'Booking tidak aktif' });
    if (!['pre_authorized','captured'].includes(booking.status_payment)) {
      await query(
        `INSERT INTO unlock_logs (log_id, vehicle_id, user_id, booking_id, aksi, sumber, berhasil) VALUES (?,?,?,?,?,'mobile_app',0)`,
        [uuidv4(), booking.vehicle_id, req.user.userId, booking_id, 'unlock']
      );
      return res.status(402).json({ success: false, message: 'Pembayaran belum dikonfirmasi (No Funds, No Key)', code: 'NO_FUNDS_NO_KEY' });
    }

    // Fase 4: validasi unlock_token — wajib ada dan cocok jika booking punya token
    if (aksi === 'unlock' && booking.unlock_token && (!unlock_token || unlock_token !== booking.unlock_token)) {
      await query(
        `INSERT INTO unlock_logs (log_id, vehicle_id, user_id, booking_id, aksi, sumber, berhasil) VALUES (?,?,?,?,?,'mobile_app',0)`,
        [uuidv4(), booking.vehicle_id, req.user.userId, booking_id, 'unlock']
      );
      return res.status(403).json({ success: false, message: 'Token kunci tidak valid', code: 'INVALID_TOKEN' });
    }

    const statusKunci = aksi === 'unlock' ? 'unlocked' : 'locked';
    const statusMesin = aksi === 'unlock' ? 'on' : 'off';

    await query(
      `INSERT INTO iot_logs (log_id, vehicle_id, booking_id, status_mesin, status_kunci, kecepatan) VALUES (?,?,?,?,?,0)`,
      [uuidv4(), booking.vehicle_id, booking_id, statusMesin, statusKunci]
    );
    await query(
      `INSERT INTO unlock_logs (log_id, vehicle_id, user_id, booking_id, aksi, sumber, berhasil) VALUES (?,?,?,?,?,'mobile_app',1)`,
      [uuidv4(), booking.vehicle_id, req.user.userId, booking_id, aksi === 'unlock' ? 'unlock' : 'lock']
    );

    let emitLat, emitLng;
    if (aksi === 'unlock') {
      emitLat = -7.7972 + (Math.random() - 0.5) * 0.01;
      emitLng = 110.3688 + (Math.random() - 0.5) * 0.01;
      await query('UPDATE vehicles SET lokasi_lat=?, lokasi_lng=? WHERE vehicle_id=?',
        [emitLat, emitLng, booking.vehicle_id]);
    } else {
      const vPos = await query('SELECT lokasi_lat, lokasi_lng FROM vehicles WHERE vehicle_id=?', [booking.vehicle_id]);
      emitLat = parseFloat(vPos[0]?.lokasi_lat || -7.7972);
      emitLng = parseFloat(vPos[0]?.lokasi_lng || 110.3688);
    }

    // Emit ke vendor pemilik kendaraan
    const vRows = await query('SELECT vendor_id FROM vehicles WHERE vehicle_id=?', [booking.vehicle_id]);
    if (vRows[0]) {
      const io = req.app.get('io');
      if (io) {
        io.to(`vendor:${vRows[0].vendor_id}`).emit('vehicle:update', {
          vehicle_id:   booking.vehicle_id,
          status_kunci: statusKunci,
          status_mesin: statusMesin,
          lokasi_lat:   emitLat,
          lokasi_lng:   emitLng,
          kecepatan:    0,
          timestamp:    new Date().toISOString(),
        });
      }
    }

    res.json({
      success: true,
      message: aksi === 'unlock' ? 'Kendaraan berhasil dibuka' : 'Kendaraan berhasil dikunci',
      data: { vehicle_id: booking.vehicle_id, status_kunci: statusKunci, status_mesin: statusMesin,
              timestamp: new Date().toISOString() }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/iot/vendor/lock - kontrol kunci dari sisi vendor (force/emergency lock, unlock)
r1.post('/vendor/lock', vendorMiddleware, async (req, res) => {
  try {
    const { vehicle_id, aksi } = req.body;
    const validAksi = ['force_lock', 'emergency_lock', 'unlock'];
    if (!vehicle_id || !validAksi.includes(aksi))
      return res.status(400).json({ success: false, message: `vehicle_id wajib dan aksi harus salah satu dari: ${validAksi.join(', ')}` });

    const vRows = await query('SELECT vendor_id FROM vehicles WHERE vehicle_id=?', [vehicle_id]);
    if (!vRows[0]) return res.status(404).json({ success: false, message: 'Kendaraan tidak ditemukan' });
    if (vRows[0].vendor_id !== req.vendor.vendorId)
      return res.status(403).json({ success: false, message: 'Akses ditolak' });

    const isUnlock = aksi === 'unlock';
    const statusKunci = isUnlock ? 'unlocked' : 'locked';
    const statusMesin = isUnlock ? 'on' : 'off';

    // Booking aktif (jika ada) untuk dikaitkan ke log dan diberi notifikasi
    const bRows = await query(
      "SELECT booking_id, user_id FROM bookings WHERE vehicle_id=? AND status_booking='active' ORDER BY created_at DESC LIMIT 1",
      [vehicle_id]
    );
    const activeBooking = bRows[0];

    await query(
      `INSERT INTO iot_logs (log_id, vehicle_id, booking_id, status_mesin, status_kunci, kecepatan) VALUES (?,?,?,?,?,0)`,
      [uuidv4(), vehicle_id, activeBooking?.booking_id || null, statusMesin, statusKunci]
    );
    await query(
      `INSERT INTO unlock_logs (log_id, vehicle_id, user_id, booking_id, aksi, sumber, berhasil) VALUES (?,?,?,?,?,'vendor_dashboard',1)`,
      [uuidv4(), vehicle_id, activeBooking?.user_id || null, activeBooking?.booking_id || null, aksi]
    );

    const vPos = await query('SELECT lokasi_lat, lokasi_lng FROM vehicles WHERE vehicle_id=?', [vehicle_id]);
    const emitLat = parseFloat(vPos[0]?.lokasi_lat || -7.7972);
    const emitLng = parseFloat(vPos[0]?.lokasi_lng || 110.3688);

    const io = req.app.get('io');
    if (io) {
      const payload = {
        vehicle_id, status_kunci: statusKunci, status_mesin: statusMesin,
        lokasi_lat: emitLat, lokasi_lng: emitLng, kecepatan: 0,
        timestamp: new Date().toISOString(),
      };
      io.to(`vendor:${req.vendor.vendorId}`).emit('vehicle:update', payload);
      if (activeBooking) io.to(`user:${activeBooking.user_id}`).emit('vehicle:update', payload);
    }

    res.json({
      success: true,
      message: isUnlock ? 'Kendaraan dibuka oleh vendor' : 'Kendaraan dikunci oleh vendor',
      data: { vehicle_id, status_kunci: statusKunci, status_mesin: statusMesin }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

r1.get('/status/:vehicle_id', authMiddleware, async (req, res) => {
  try {
    const rows = await query(
      `SELECT status_mesin, status_kunci, lokasi_lat, lokasi_lng, kecepatan, waktu_update
       FROM iot_logs WHERE vehicle_id=? ORDER BY waktu_update DESC LIMIT 1`, [req.params.vehicle_id]
    );
    const status = rows[0] || { status_mesin: 'off', status_kunci: 'locked', kecepatan: 0 };
    if (status.status_mesin === 'on') {
      status.kecepatan = Math.round(Math.random() * 40);
      status.lokasi_lat = (status.lokasi_lat || -7.7972) + (Math.random() - 0.5) * 0.0001;
      status.lokasi_lng = (status.lokasi_lng || 110.3688) + (Math.random() - 0.5) * 0.0001;
    }
    res.json({ success: true, data: status });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = r1;
