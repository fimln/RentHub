const express = require('express');
const router  = express.Router();
const { v4: uuidv4 } = require('uuid');
const { pool, query } = require('../../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');
const { checkAndAutoSuspend } = require('./vendor.routes');
const { deduct, credit } = require('../utils/wallet');

// POST /api/bookings/estimate - Fase 3
router.post('/estimate', authMiddleware, async (req, res) => {
  try {
    const { vehicle_id, durasi_jam, durasi_hari, geofence_id, metode_pengambilan } = req.body;
    if (!vehicle_id || (!durasi_jam && !durasi_hari))
      return res.status(400).json({ success: false, message: 'vehicle_id dan durasi_jam atau durasi_hari wajib diisi' });

    const vRows = await query(
      `SELECT v.tarif_per_jam, v.tarif_per_hari, v.vendor_id, vn.biaya_antar
       FROM vehicles v
       JOIN vendors vn ON v.vendor_id = vn.vendor_id
       WHERE v.vehicle_id=?`,
      [vehicle_id]
    );
    if (!vRows[0])
      return res.status(404).json({ success: false, message: 'Kendaraan tidak ditemukan' });

    let pickupFee = 0;
    if (geofence_id) {
      const geo = await query('SELECT pickup_fee FROM geofences WHERE geofence_id=?', [geofence_id]);
      pickupFee = parseFloat(geo[0]?.pickup_fee || 0);
    }

    let biayaSewa;
    let jamEfektif;
    let hariEfektif;
    const tarifPerHari = vRows[0].tarif_per_hari ? parseFloat(vRows[0].tarif_per_hari) : 70000;

    if (durasi_hari) {
      hariEfektif = parseInt(durasi_hari);
      jamEfektif = hariEfektif * 24;
      biayaSewa = tarifPerHari * hariEfektif;
    } else {
      jamEfektif = parseInt(durasi_jam);
      biayaSewa = parseFloat(vRows[0].tarif_per_jam) * jamEfektif;
    }

    const deliveryFee = metode_pengambilan === 'diantar' ? parseFloat(vRows[0].biaya_antar || 0) : 0;
    const depositVirtual = Math.max(150000, biayaSewa * 0.5);
    const total = biayaSewa + pickupFee + deliveryFee + depositVirtual;

    res.json({
      success: true,
      data: {
        biaya_sewa: biayaSewa,
        tarif_per_hari: tarifPerHari,
        pickup_fee: pickupFee,
        delivery_fee: deliveryFee,
        deposit_virtual: depositVirtual,
        total
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/bookings - atomic booking + payment (Fase 4)
router.post('/', authMiddleware, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const { vehicle_id, geofence_id, waktu_mulai, durasi_jam, durasi_hari, metode_bayar, metode_pengambilan, catatan } = req.body;
    const user_id = req.user.userId;

    if (!vehicle_id || !waktu_mulai || (!durasi_jam && !durasi_hari))
      return res.status(400).json({ success: false, message: 'vehicle_id, waktu_mulai, dan durasi_jam atau durasi_hari wajib diisi' });

    await conn.beginTransaction();

    // 1. Lock vehicle row
    const [vRows] = await conn.execute(
      'SELECT vehicle_id, status, tarif_per_jam, tarif_per_hari, vendor_id FROM vehicles WHERE vehicle_id=? FOR UPDATE',
      [vehicle_id]
    );
    if (!vRows[0] || vRows[0].status !== 'available') {
      await conn.rollback();
      return res.status(409).json({ success: false, message: 'Kendaraan tidak tersedia' });
    }

    // 1b. Check vendor suspension
    const vendorStatus = await checkAndAutoSuspend(vRows[0].vendor_id);
    if (vendorStatus === 'suspended') {
      await conn.rollback();
      return res.status(403).json({ success: false, message: 'Vendor sedang suspended. Kendaraan tidak dapat dipesan saat ini.' });
    }

    // 2. Lock user row
    const [userRows] = await conn.execute(
      'SELECT user_id, status_verifikasi, saldo_ewallet, trust_score FROM users WHERE user_id=? FOR UPDATE',
      [user_id]
    );
    if (!userRows[0]) {
      await conn.rollback();
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
    }
    if (userRows[0].status_verifikasi !== 'verified') {
      await conn.rollback();
      return res.status(403).json({ success: false, message: 'Identitas belum diverifikasi. Verifikasi NIK/SIM terlebih dahulu.' });
    }

    // 3. Hitung biaya (formula sama dengan /estimate)
    let pickupFee = 0;
    if (geofence_id) {
      const [geoRows] = await conn.execute('SELECT pickup_fee FROM geofences WHERE geofence_id=?', [geofence_id]);
      pickupFee = parseFloat(geoRows[0]?.pickup_fee || 0);
    }

    let biayaSewa;
    let jamEfektif;
    const tarifPerHari = vRows[0].tarif_per_hari ? parseFloat(vRows[0].tarif_per_hari) : 70000;

    if (durasi_hari) {
      const hariEfektif = parseInt(durasi_hari);
      jamEfektif = hariEfektif * 24;
      biayaSewa = tarifPerHari * hariEfektif;
    } else {
      jamEfektif = parseInt(durasi_jam);
      biayaSewa = parseFloat(vRows[0].tarif_per_jam) * jamEfektif;
    }

    const metodePengambilan = metode_pengambilan || 'ambil_sendiri';
    let deliveryFee = 0;
    if (metodePengambilan === 'diantar') {
      const [vendorRows] = await conn.execute('SELECT biaya_antar FROM vendors WHERE vendor_id=?', [vRows[0].vendor_id]);
      deliveryFee = parseFloat(vendorRows[0]?.biaya_antar || 0);
    }

    const depositVirtual = Math.max(150000, biayaSewa * 0.5);
    const totalBayar = biayaSewa + pickupFee + deliveryFee + depositVirtual;

    // 4. Cek saldo pada metode bayar yang dipilih
    const chosenMethod = metode_bayar || 'gopay';
    const [methodRows] = await conn.execute(
      'SELECT saldo FROM ewallet_accounts WHERE user_id=? AND metode_bayar=? FOR UPDATE',
      [user_id, chosenMethod]
    );
    const methodSaldo = parseFloat(methodRows[0]?.saldo ?? -1);
    if (methodSaldo < 0) {
      await conn.rollback();
      return res.status(400).json({ success: false, message: `Metode bayar ${chosenMethod} tidak terdaftar` });
    }
    if (methodSaldo < totalBayar) {
      const oldScore = userRows[0].trust_score;
      const delta = parseInt(process.env.TRUST_SCORE_GAGAL_BAYAR || -5);
      const newScore = Math.max(0, oldScore + delta);
      await conn.execute('UPDATE users SET trust_score=? WHERE user_id=?', [newScore, user_id]);
      await conn.execute(
        `INSERT INTO trust_logs (log_id, user_id, parameter, delta_skor, skor_sebelum, skor_sesudah, keterangan)
         VALUES (?,?,?,?,?,?,?)`,
        [uuidv4(), user_id, 'saldo_tidak_cukup', delta, oldScore, newScore, 'Gagal booking: saldo tidak mencukupi']
      );
      await conn.commit();
      return res.status(402).json({
        success: false,
        error: { code: 'INSUFFICIENT_FUNDS' },
        message: `Saldo ${chosenMethod} tidak mencukupi. Saldo: Rp${methodSaldo.toLocaleString()}, perlu: Rp${totalBayar.toLocaleString()}`
      });
    }

    // 5. Buat booking (status langsung active)
    const bookingId = uuidv4();
    const unlockToken = uuidv4();
    const waktuMulai = new Date(waktu_mulai);
    const waktuSelesai = new Date(waktuMulai.getTime() + jamEfektif * 3600000);

    await conn.execute(
      `INSERT INTO bookings (booking_id, user_id, vehicle_id, geofence_id, waktu_mulai, waktu_selesai,
       durasi_jam, pickup_fee, delivery_fee, metode_pengambilan, unlock_token, catatan, status_booking)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,'active')`,
      [bookingId, user_id, vehicle_id, geofence_id || null, waktuMulai, waktuSelesai,
       jamEfektif, pickupFee, deliveryFee, metodePengambilan, unlockToken, catatan || null]
    );

    // 6. Buat payment pre_authorized
    const paymentId = uuidv4();
    const gatewayRef = `RH-${Date.now()}-${Math.random().toString(36).substr(2, 6).toUpperCase()}`;
    await conn.execute(
      `INSERT INTO payments (payment_id, booking_id, biaya_sewa, deposit_virtual, pickup_fee,
       total_bayar, metode_bayar, status_payment, gateway_ref, paid_at)
       VALUES (?,?,?,?,?,?,?,'pre_authorized',?,NOW())`,
      [paymentId, bookingId, biayaSewa, depositVirtual, pickupFee, totalBayar,
       chosenMethod, gatewayRef]
    );

    // 7. Kurangi saldo dari metode bayar terpilih (atomic + ledger)
    await deduct(conn, { userId: user_id, metodeBayar: chosenMethod, amount: totalBayar,
                         refBookingId: bookingId, keterangan: `Pembayaran booking ${bookingId.substr(0,8)}`, tipe: 'deduct' });

    // 8. Status kendaraan -> rented (sudah dibayar, siap digunakan)
    await conn.execute("UPDATE vehicles SET status='rented' WHERE vehicle_id=?", [vehicle_id]);

    // 9. IoT log awal: kendaraan terkunci
    await conn.execute(
      `INSERT INTO iot_logs (log_id, vehicle_id, booking_id, status_mesin, status_kunci, kecepatan)
       VALUES (?,?,?,'off','locked',0)`,
      [uuidv4(), vehicle_id, bookingId]
    );

    // 10. Notifikasi vendor
    const vendorId = vRows[0].vendor_id;
    await conn.execute(
      `INSERT INTO notifications (notif_id, vendor_id, tipe, judul, pesan) VALUES (?,?,'vehicle_rented','Kendaraan Disewa',?)`,
      [uuidv4(), vendorId, `Booking baru. Total: Rp${totalBayar.toLocaleString()}.`]
    );

    // 11. Trust log untuk audit trail
    await conn.execute(
      `INSERT INTO trust_logs (log_id, user_id, booking_id, parameter, delta_skor, skor_sebelum, skor_sesudah, keterangan)
       VALUES (?,?,?,?,?,?,?,?)`,
      [uuidv4(), user_id, bookingId, 'booking_created', 0,
       userRows[0].trust_score, userRows[0].trust_score, 'Booking berhasil dibuat']
    );

    await conn.commit();

    const io = req.app.get('io');
    if (io) {
      io.to(`vendor:${vendorId}`).emit('booking:new', {
        booking_id: bookingId, vehicle_id, total_bayar: totalBayar, timestamp: new Date().toISOString()
      });
    }

    res.status(201).json({
      success: true,
      message: 'Booking berhasil',
      data: {
        booking_id: bookingId,
        unlock_token: unlockToken,
        status_booking: 'active',
        waktu_mulai: waktuMulai,
        waktu_selesai: waktuSelesai,
        durasi_jam: jamEfektif,
        metode_pengambilan: metodePengambilan,
        payment_summary: {
          payment_id: paymentId,
          biaya_sewa: biayaSewa,
          deposit_virtual: depositVirtual,
          pickup_fee: pickupFee,
          delivery_fee: deliveryFee,
          total_bayar: totalBayar,
          saldo_setelah: methodSaldo - totalBayar,
        }
      }
    });
  } catch (err) {
    await conn.rollback().catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  } finally {
    conn.release();
  }
});

// GET /api/bookings/my
router.get('/my', authMiddleware, async (req, res) => {
  try {
    const rows = await query(
      'SELECT * FROM v_booking_detail WHERE user_id=? ORDER BY created_at DESC LIMIT 20',
      [req.user.userId]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/bookings/:id
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const rows = await query('SELECT * FROM v_booking_detail WHERE booking_id=?', [req.params.id]);
    if (!rows[0]) return res.status(404).json({ success: false, message: 'Booking tidak ditemukan' });
    res.json({ success: true, data: rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/bookings/:id/audit - Fase 6
router.get('/:id/audit', authMiddleware, async (req, res) => {
  try {
    const bRows = await query('SELECT user_id FROM bookings WHERE booking_id=?', [req.params.id]);
    if (!bRows[0]) return res.status(404).json({ success: false, message: 'Booking tidak ditemukan' });
    if (bRows[0].user_id !== req.user.userId)
      return res.status(403).json({ success: false, message: 'Akses ditolak' });

    const [trustLogs, unlockLogs, iotLogs, penalties, payment] = await Promise.all([
      query('SELECT log_id, parameter, delta_skor, skor_sebelum, skor_sesudah, keterangan, created_at FROM trust_logs WHERE booking_id=? ORDER BY created_at ASC', [req.params.id]),
      query('SELECT log_id, aksi, sumber, berhasil, waktu_aksi AS created_at FROM unlock_logs WHERE booking_id=? ORDER BY waktu_aksi ASC', [req.params.id]),
      query('SELECT log_id, status_mesin, status_kunci, kecepatan, waktu_update FROM iot_logs WHERE booking_id=? ORDER BY waktu_update ASC', [req.params.id]),
      query('SELECT * FROM penalties WHERE booking_id=?', [req.params.id]),
      query('SELECT payment_id, total_bayar, deposit_virtual, biaya_sewa, pickup_fee, status_payment, refund_amount, metode_bayar, paid_at FROM payments WHERE booking_id=?', [req.params.id]),
    ]);

    res.json({
      success: true,
      data: { trust_logs: trustLogs, unlock_logs: unlockLogs, iot_logs: iotLogs, penalties, payment: payment[0] || null }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/bookings/:id/return - Fase 5: penalty 1.5x + geofence trust -15
router.post('/:id/return', authMiddleware, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const { lat, lng } = req.body;

    const [bookingRows] = await conn.execute(
      `SELECT b.*, v.tarif_per_jam, v.tarif_per_hari, v.vendor_id, vn.biaya_antar,
              COALESCE(vs.komisi_platform, 7) AS komisi_platform,
              g.latitude AS geo_lat, g.longitude AS geo_lng,
              g.radius_meter, p.deposit_virtual, p.payment_id, p.biaya_sewa, p.pickup_fee, p.metode_bayar
       FROM bookings b
       LEFT JOIN vehicles v ON b.vehicle_id = v.vehicle_id
       LEFT JOIN vendors vn ON v.vendor_id = vn.vendor_id
       LEFT JOIN vendor_subscriptions vs ON vn.subscription_id = vs.subscription_id
       LEFT JOIN geofences g ON b.geofence_id = g.geofence_id
       LEFT JOIN payments p ON b.booking_id = p.booking_id
       WHERE b.booking_id=? AND b.user_id=? FOR UPDATE`,
      [req.params.id, req.user.userId]
    );
    const booking = bookingRows[0];
    if (!booking) {
      await conn.rollback();
      return res.status(404).json({ success: false, message: 'Booking tidak ditemukan' });
    }
    if (booking.status_booking !== 'active') {
      await conn.rollback();
      return res.status(400).json({ success: false, message: 'Booking tidak aktif' });
    }

    // Hitung jarak ke geofence
    let geofenceValid = true;
    let distanceM = 0;
    if (lat && lng && booking.geo_lat && booking.geo_lng) {
      const R = 6371000;
      const dLat = (lat - booking.geo_lat) * Math.PI / 180;
      const dLng = (lng - booking.geo_lng) * Math.PI / 180;
      distanceM = Math.round(R * Math.sqrt(dLat * dLat + dLng * dLng));
      geofenceValid = distanceM <= (booking.radius_meter || 100);
    }

    const now = new Date();
    const overtime = Math.max(0, (now - new Date(booking.waktu_selesai)) / 60000);
    let refundAmount = parseFloat(booking.deposit_virtual || 0);
    let penalty = 0;
    let trustDelta = 0;
    let trustParam = '';

    if (overtime > 0) {
      // Fase 5: denda dengan multiplier 1.5x, basis tarif harian (konsisten dengan model harga)
      const tarifDenda = (parseFloat(booking.tarif_per_hari) / 24) * 1.5;
      const jamLambat = Math.ceil(overtime / 60);
      penalty = Math.min(jamLambat * tarifDenda, refundAmount);
      refundAmount -= penalty;
      await conn.execute(
        `INSERT INTO penalties (penalty_id, booking_id, durasi_overtime_menit, tarif_per_jam_denda, nominal_denda, status_potong, auto_deduct_at)
         VALUES (?,?,?,?,?,'deducted',NOW())`,
        [uuidv4(), req.params.id, Math.round(overtime), tarifDenda, penalty]
      );
      trustDelta = overtime <= 60
        ? parseInt(process.env.TRUST_SCORE_OVERTIME_RINGAN || -10)
        : parseInt(process.env.TRUST_SCORE_OVERTIME_BERAT  || -20);
      trustParam = overtime <= 60 ? 'keterlambatan_ringan' : 'keterlambatan_berat';
    } else {
      trustDelta = parseInt(process.env.TRUST_SCORE_TEPAT_WAKTU || 10);
      trustParam = 'sewa_selesai_tepat_waktu';
    }

    // Update booking
    await conn.execute(
      `UPDATE bookings SET status_booking='completed', waktu_aktual_kembali=NOW(), geofence_validated=? WHERE booking_id=?`,
      [geofenceValid ? 1 : 0, req.params.id]
    );
    // Update payment — on-time stays 'captured' (income realized, deposit released); overtime → 'partially_refunded'
    if (booking.payment_id) {
      await conn.execute(
        `UPDATE payments SET refund_amount=?, status_payment=?, deposit_dilepas_at=NOW() WHERE payment_id=?`,
        [refundAmount, penalty > 0 ? 'partially_refunded' : 'captured', booking.payment_id]
      );
    }
    // Update vehicle
    await conn.execute("UPDATE vehicles SET status='available' WHERE vehicle_id=?", [booking.vehicle_id]);

    // Credit vendor — rate derived from komisi_platform, not hardcoded
    const komisi = parseFloat(booking.komisi_platform);
    const vendorRate = 1 - komisi / 100;
    const vendorCredit = parseFloat(booking.biaya_sewa || 0) * vendorRate
                       + parseFloat(booking.pickup_fee || 0)
                       + parseFloat(booking.delivery_fee || 0);
    await conn.execute('UPDATE vendors SET saldo=saldo+? WHERE vendor_id=?', [vendorCredit, booking.vendor_id]);

    // Update trust score (overtime / tepat waktu)
    const [userRows] = await conn.execute('SELECT trust_score FROM users WHERE user_id=? FOR UPDATE', [req.user.userId]);
    const oldScore = userRows[0].trust_score;
    let currentScore = Math.max(0, Math.min(100, oldScore + trustDelta));
    let level = currentScore >= 90 ? 'platinum' : currentScore >= 75 ? 'gold' : currentScore >= 50 ? 'silver' : 'bronze';
    await conn.execute('UPDATE users SET trust_score=?, level_trust=? WHERE user_id=?', [currentScore, level, req.user.userId]);
    await conn.execute(
      `INSERT INTO trust_logs (log_id, user_id, booking_id, parameter, delta_skor, skor_sebelum, skor_sesudah)
       VALUES (?,?,?,?,?,?,?)`,
      [uuidv4(), req.user.userId, req.params.id, trustParam, trustDelta, oldScore, currentScore]
    );

    // Fase 5: geofence violation - trust delta -15 (terpisah)
    let gfDelta = 0;
    if (!geofenceValid) {
      gfDelta = parseInt(process.env.TRUST_SCORE_GEOFENCE_BREACH || -15);
      const prevScore = currentScore;
      currentScore = Math.max(0, Math.min(100, currentScore + gfDelta));
      level = currentScore >= 90 ? 'platinum' : currentScore >= 75 ? 'gold' : currentScore >= 50 ? 'silver' : 'bronze';
      await conn.execute('UPDATE users SET trust_score=?, level_trust=? WHERE user_id=?', [currentScore, level, req.user.userId]);
      await conn.execute(
        `INSERT INTO trust_logs (log_id, user_id, booking_id, parameter, delta_skor, skor_sebelum, skor_sesudah)
         VALUES (?,?,?,?,?,?,?)`,
        [uuidv4(), req.user.userId, req.params.id, 'geofence_violation', gfDelta, prevScore, currentScore]
      );
    }

    // Refund deposit ke metode bayar asal
    if (refundAmount > 0) {
      await credit(conn, { userId: req.user.userId, metodeBayar: booking.metode_bayar || 'gopay', amount: refundAmount,
                           refBookingId: req.params.id, keterangan: `Refund deposit booking ${req.params.id.substr(0,8)}`, tipe: 'refund' });
    }

    // Notifikasi vendor
    if (booking.vendor_id) {
      await conn.execute(
        `INSERT INTO notifications (notif_id, vendor_id, tipe, judul, pesan) VALUES (?,?,'vehicle_returned','Kendaraan dikembalikan',?)`,
        [uuidv4(), booking.vendor_id, `Overtime: ${Math.round(overtime)} menit. Denda: Rp${penalty.toLocaleString()}. Kredit diterima: Rp${vendorCredit.toLocaleString()}`]
      );
    }

    await conn.commit();

    const io = req.app.get('io');
    if (io && booking.vendor_id) {
      io.to(`vendor:${booking.vendor_id}`).emit('booking:returned', {
        booking_id: req.params.id, vehicle_id: booking.vehicle_id,
        overtime_menit: Math.round(overtime), penalty_amount: penalty,
        deposit_dikembalikan: refundAmount, vendor_credit: vendorCredit,
        timestamp: new Date().toISOString(),
      });
    }

    res.json({
      success: true,
      message: 'Pengembalian berhasil',
      data: {
        overtime_menit: Math.round(overtime),
        penalty_amount: penalty,
        deposit_dikembalikan: refundAmount,
        geofence_valid: geofenceValid,
        jarak_meter: distanceM,
        trust_score_baru: currentScore,
        trust_delta: trustDelta + gfDelta,
      }
    });
  } catch (err) {
    await conn.rollback().catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  } finally {
    conn.release();
  }
});

// POST /api/bookings/:id/cancel - batalkan booking sebelum kendaraan dibuka
router.post('/:id/cancel', authMiddleware, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [bookingRows] = await conn.execute(
      `SELECT b.booking_id, b.status_booking, b.vehicle_id, v.vendor_id,
              p.payment_id, p.total_bayar, p.metode_bayar
       FROM bookings b
       LEFT JOIN vehicles v ON b.vehicle_id = v.vehicle_id
       LEFT JOIN payments p ON b.booking_id = p.booking_id
       WHERE b.booking_id=? AND b.user_id=? FOR UPDATE`,
      [req.params.id, req.user.userId]
    );
    const booking = bookingRows[0];
    if (!booking) {
      await conn.rollback();
      return res.status(404).json({ success: false, message: 'Booking tidak ditemukan' });
    }
    if (booking.status_booking !== 'active') {
      await conn.rollback();
      return res.status(400).json({ success: false, message: 'Booking tidak dapat dibatalkan' });
    }

    // Tidak boleh batal jika kendaraan sudah pernah dibuka
    const [unlockRows] = await conn.execute(
      "SELECT COUNT(*) AS total FROM unlock_logs WHERE booking_id=? AND aksi='unlock'",
      [req.params.id]
    );
    if (unlockRows[0].total > 0) {
      await conn.rollback();
      return res.status(409).json({ success: false, message: 'Kendaraan sudah dibuka, booking tidak bisa dibatalkan' });
    }

    const refundAmount = parseFloat(booking.total_bayar || 0);

    // Refund penuh ke metode bayar asal
    if (refundAmount > 0) {
      await credit(conn, { userId: req.user.userId, metodeBayar: booking.metode_bayar || 'gopay', amount: refundAmount,
                           refBookingId: req.params.id, keterangan: `Pembatalan booking ${req.params.id.substr(0,8)}`, tipe: 'refund' });
    }

    await conn.execute("UPDATE bookings SET status_booking='cancelled' WHERE booking_id=?", [req.params.id]);
    if (booking.payment_id) {
      await conn.execute(
        "UPDATE payments SET status_payment='refunded', refund_amount=? WHERE payment_id=?",
        [refundAmount, booking.payment_id]
      );
    }
    await conn.execute("UPDATE vehicles SET status='available' WHERE vehicle_id=?", [booking.vehicle_id]);

    if (booking.vendor_id) {
      await conn.execute(
        `INSERT INTO notifications (notif_id, vendor_id, tipe, judul, pesan) VALUES (?,?,'booking_cancelled','Booking dibatalkan',?)`,
        [uuidv4(), booking.vendor_id, `Penyewa membatalkan booking. Dana Rp${refundAmount.toLocaleString()} dikembalikan.`]
      );
    }

    await conn.commit();

    const io = req.app.get('io');
    if (io && booking.vendor_id) {
      io.to(`vendor:${booking.vendor_id}`).emit('booking:cancelled', {
        booking_id: req.params.id, vehicle_id: booking.vehicle_id, timestamp: new Date().toISOString(),
      });
    }

    res.json({ success: true, message: 'Booking dibatalkan', data: { refund_amount: refundAmount } });
  } catch (err) {
    await conn.rollback().catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  } finally {
    conn.release();
  }
});

module.exports = router;
