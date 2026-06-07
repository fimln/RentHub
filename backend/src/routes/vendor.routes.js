const express = require('express');
const r = express.Router();
const { pool, query } = require('../../config/database');
const { vendorMiddleware } = require('../middleware/auth.middleware');
const { credit } = require('../utils/wallet');
const { v4: uuidv4 } = require('uuid');

async function checkAndAutoSuspend(vendorId) {
  const rows = await query(
    'SELECT status_langganan, tanggal_jatuh_tempo FROM vendors WHERE vendor_id=?',
    [vendorId]
  );
  if (!rows[0]) return 'suspended';
  const { status_langganan, tanggal_jatuh_tempo } = rows[0];
  if (status_langganan === 'active' && tanggal_jatuh_tempo) {
    const cutoff = new Date(tanggal_jatuh_tempo);
    cutoff.setDate(cutoff.getDate() + 3);
    if (new Date() > cutoff) {
      await query("UPDATE vendors SET status_langganan='suspended' WHERE vendor_id=?", [vendorId]);
      return 'suspended';
    }
  }
  return status_langganan;
}

r.get('/dashboard', vendorMiddleware, async (req, res) => {
  try {
    const rows = await query('SELECT * FROM v_vendor_dashboard WHERE vendor_id=?', [req.vendor.vendorId]);
    res.json({ success: true, data: rows[0] || {} });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

r.get('/fleet', vendorMiddleware, async (req, res) => {
  try {
    const rows = await query(
      `SELECT v.*,
         il.status_mesin, il.status_kunci, il.kecepatan, il.waktu_update AS iot_update
       FROM vehicles v
       LEFT JOIN iot_logs il ON il.log_id = (
         SELECT log_id FROM iot_logs WHERE vehicle_id=v.vehicle_id ORDER BY waktu_update DESC LIMIT 1
       )
       WHERE v.vendor_id=? ORDER BY v.status, v.merek`, [req.vendor.vendorId]
    );
    rows.forEach(r => { try { r.fitur = JSON.parse(r.fitur || '[]'); } catch { r.fitur = []; } });
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

r.get('/bookings', vendorMiddleware, async (req, res) => {
  try {
    const { vehicle_id } = req.query;
    let sql = 'SELECT * FROM v_booking_detail WHERE vendor_id=?';
    const params = [req.vendor.vendorId];
    if (vehicle_id) { sql += ' AND vehicle_id=?'; params.push(vehicle_id); }
    sql += ' ORDER BY created_at DESC LIMIT 50';
    const rows = await query(sql, params);
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

r.post('/fleet', vendorMiddleware, async (req, res) => {
  try {
    const vendorId = req.vendor.vendorId;

    const status = await checkAndAutoSuspend(vendorId);
    if (status === 'suspended')
      return res.status(403).json({ success: false, message: 'Langganan suspended. Perbarui pembayaran untuk menambah kendaraan.' });

    const subRows = await query(
      `SELECT vs.maks_armada, vs.kategori
       FROM vendors vn
       JOIN vendor_subscriptions vs ON vn.subscription_id = vs.subscription_id
       WHERE vn.vendor_id=?`,
      [vendorId]
    );
    const sub = subRows[0];
    if (!sub) return res.status(500).json({ success: false, message: 'Data langganan tidak ditemukan' });

    if (sub.maks_armada !== null) {
      const countRows = await query(
        "SELECT COUNT(*) AS total FROM vehicles WHERE vendor_id=? AND status != 'inactive'",
        [vendorId]
      );
      const total = countRows[0].total;
      if (total >= sub.maks_armada)
        return res.status(409).json({
          success: false,
          message: `Batas armada kategori ${sub.kategori} (maks ${sub.maks_armada} unit) telah tercapai. Upgrade langganan untuk menambah lebih banyak kendaraan.`
        });
    }

    const { merek, model, tahun, plat_nomor, tarif_per_hari, tarif_per_jam, tarif_deposit,
            warna, deskripsi, fitur, foto_url, kapasitas, lokasi_lat, lokasi_lng } = req.body;

    if (!merek || !model || !tahun || !plat_nomor || !tarif_per_hari)
      return res.status(400).json({ success: false, message: 'merek, model, tahun, plat_nomor, tarif_per_hari wajib diisi' });

    const tarifHari = parseFloat(tarif_per_hari);
    const tarifJam = tarif_per_jam ? parseFloat(tarif_per_jam) : tarifHari / 24;
    const deposit = tarif_deposit ? parseFloat(tarif_deposit) : Math.max(150000, tarifHari * 0.5);

    const korRows = await query(
      "SELECT nomor_stnk, tanggal_berlaku_stnk, status_aktif FROM korlantas_kendaraan WHERE nomor_plat=?",
      [plat_nomor]
    );
    const kor = korRows[0];

    let vehicleStatus = 'inactive';
    let nomorStnk = null;
    let verified = false;
    let verifyMessage = null;

    if (!kor || !kor.status_aktif) {
      verifyMessage = 'Kendaraan ditambahkan namun gagal verifikasi Korlantas. Plat nomor tidak ditemukan atau tidak aktif.';
    } else {
      nomorStnk = kor.nomor_stnk;
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const berlaku = new Date(kor.tanggal_berlaku_stnk);
      if (berlaku >= today) {
        vehicleStatus = 'available';
        verified = true;
      } else {
        verifyMessage = 'Kendaraan ditambahkan namun STNK telah kadaluarsa. Status kendaraan diset inactive.';
      }
    }

    const vehicleId = uuidv4();
    await query(
      `INSERT INTO vehicles
         (vehicle_id, vendor_id, jenis, merek, model, tahun, plat_nomor, nomor_stnk, warna,
          status, tarif_per_jam, tarif_per_hari, tarif_deposit, kapasitas, foto_url,
          deskripsi, fitur, lokasi_lat, lokasi_lng)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
      [
        vehicleId, vendorId, 'motor', merek, model, parseInt(tahun), plat_nomor, nomorStnk,
        warna || null, vehicleStatus, tarifJam, tarifHari, deposit,
        kapasitas ? parseInt(kapasitas) : 2, foto_url || null, deskripsi || null,
        fitur ? JSON.stringify(fitur) : null,
        lokasi_lat || null, lokasi_lng || null
      ]
    );

    const created = await query('SELECT * FROM vehicles WHERE vehicle_id=?', [vehicleId]);
    const vehicle = created[0];
    try { vehicle.fitur = JSON.parse(vehicle.fitur || '[]'); } catch { vehicle.fitur = []; }

    res.status(201).json({ success: true, verified, message: verifyMessage, data: vehicle });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

r.put('/fleet/:vehicle_id', vendorMiddleware, async (req, res) => {
  try {
    const { vehicle_id } = req.params;
    const vendorId = req.vendor.vendorId;

    const existing = await query(
      'SELECT * FROM vehicles WHERE vehicle_id=? AND vendor_id=?',
      [vehicle_id, vendorId]
    );
    if (!existing[0]) return res.status(404).json({ success: false, message: 'Kendaraan tidak ditemukan' });

    const allowed = ['merek', 'model', 'tahun', 'warna', 'tarif_per_jam', 'tarif_per_hari',
                     'tarif_deposit', 'status', 'deskripsi', 'fitur', 'foto_url', 'kapasitas'];
    const validStatuses = ['available', 'maintenance', 'inactive'];

    const updates = [];
    const values = [];

    for (const field of allowed) {
      if (req.body[field] === undefined) continue;
      if (field === 'status') {
        if (!validStatuses.includes(req.body[field]))
          return res.status(400).json({ success: false, message: `Status harus salah satu dari: ${validStatuses.join(', ')}` });
      }
      let val = req.body[field];
      if (['tarif_per_jam', 'tarif_per_hari', 'tarif_deposit'].includes(field)) val = parseFloat(val);
      if (field === 'tahun' || field === 'kapasitas') val = parseInt(val);
      if (field === 'fitur') val = JSON.stringify(val);
      updates.push(`${field}=?`);
      values.push(val);
    }

    if (updates.length === 0)
      return res.status(400).json({ success: false, message: 'Tidak ada field yang diupdate' });

    values.push(vehicle_id);
    await query(`UPDATE vehicles SET ${updates.join(', ')} WHERE vehicle_id=?`, values);

    const updated = await query('SELECT * FROM vehicles WHERE vehicle_id=?', [vehicle_id]);
    const vehicle = updated[0];
    try { vehicle.fitur = JSON.parse(vehicle.fitur || '[]'); } catch { vehicle.fitur = []; }

    res.json({ success: true, data: vehicle });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

r.delete('/fleet/:vehicle_id', vendorMiddleware, async (req, res) => {
  try {
    const { vehicle_id } = req.params;
    const vendorId = req.vendor.vendorId;

    const rows = await query(
      'SELECT status FROM vehicles WHERE vehicle_id=? AND vendor_id=?',
      [vehicle_id, vendorId]
    );
    if (!rows[0]) return res.status(404).json({ success: false, message: 'Kendaraan tidak ditemukan' });
    if (rows[0].status === 'rented')
      return res.status(409).json({ success: false, message: 'Kendaraan sedang disewa dan tidak dapat dihapus' });

    await query("UPDATE vehicles SET status='inactive' WHERE vehicle_id=?", [vehicle_id]);
    res.json({ success: true, message: 'Kendaraan berhasil dinonaktifkan' });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// PUT /api/vendors/profile - update pengaturan vendor (mis. biaya antar)
r.put('/profile', vendorMiddleware, async (req, res) => {
  try {
    const allowed = ['biaya_antar', 'kontak_phone', 'alamat', 'kota'];
    const updates = [];
    const values = [];

    for (const field of allowed) {
      if (req.body[field] === undefined) continue;
      let val = req.body[field];
      if (field === 'biaya_antar') {
        val = parseFloat(val);
        if (isNaN(val) || val < 0)
          return res.status(400).json({ success: false, message: 'biaya_antar harus angka >= 0' });
      }
      updates.push(`${field}=?`);
      values.push(val);
    }

    if (updates.length === 0)
      return res.status(400).json({ success: false, message: 'Tidak ada field yang diupdate' });

    values.push(req.vendor.vendorId);
    await query(`UPDATE vendors SET ${updates.join(', ')} WHERE vendor_id=?`, values);

    const rows = await query(
      'SELECT vendor_id, nama_vendor, kontak_phone, alamat, kota, biaya_antar FROM vendors WHERE vendor_id=?',
      [req.vendor.vendorId]
    );
    res.json({ success: true, data: rows[0] });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// GET /api/vendors/bookings/:booking_id/penalties - denda untuk booking milik vendor
r.get('/bookings/:booking_id/penalties', vendorMiddleware, async (req, res) => {
  try {
    const own = await query(
      `SELECT v.vendor_id FROM bookings b
       JOIN vehicles v ON b.vehicle_id = v.vehicle_id
       WHERE b.booking_id=?`,
      [req.params.booking_id]
    );
    if (!own[0]) return res.status(404).json({ success: false, message: 'Booking tidak ditemukan' });
    if (own[0].vendor_id !== req.vendor.vendorId)
      return res.status(403).json({ success: false, message: 'Akses ditolak' });

    const rows = await query(
      'SELECT penalty_id, durasi_overtime_menit, tarif_per_jam_denda, nominal_denda, status_potong, created_at FROM penalties WHERE booking_id=? ORDER BY created_at DESC',
      [req.params.booking_id]
    );
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// POST /api/vendors/penalties/:penalty_id/waive - bebaskan denda, refund ke penyewa
r.post('/penalties/:penalty_id/waive', vendorMiddleware, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [rows] = await conn.execute(
      `SELECT pn.penalty_id, pn.status_potong, pn.nominal_denda,
              b.booking_id, b.user_id, v.vendor_id,
              p.payment_id, p.metode_bayar, p.refund_amount
       FROM penalties pn
       JOIN bookings b ON pn.booking_id = b.booking_id
       JOIN vehicles v ON b.vehicle_id = v.vehicle_id
       LEFT JOIN payments p ON b.booking_id = p.booking_id
       WHERE pn.penalty_id=? FOR UPDATE`,
      [req.params.penalty_id]
    );
    const pen = rows[0];
    if (!pen) {
      await conn.rollback();
      return res.status(404).json({ success: false, message: 'Denda tidak ditemukan' });
    }
    if (pen.vendor_id !== req.vendor.vendorId) {
      await conn.rollback();
      return res.status(403).json({ success: false, message: 'Akses ditolak' });
    }
    if (pen.status_potong !== 'deducted') {
      await conn.rollback();
      return res.status(400).json({ success: false, message: 'Denda tidak dalam status terpotong' });
    }

    const nominal = parseFloat(pen.nominal_denda || 0);

    if (nominal > 0) {
      await credit(conn, { userId: pen.user_id, metodeBayar: pen.metode_bayar || 'gopay', amount: nominal,
                           refBookingId: pen.booking_id, keterangan: `Pembebasan denda booking ${pen.booking_id.substr(0,8)}`, tipe: 'refund' });
    }

    await conn.execute("UPDATE penalties SET status_potong='waived' WHERE penalty_id=?", [req.params.penalty_id]);
    if (pen.payment_id) {
      await conn.execute(
        'UPDATE payments SET refund_amount=refund_amount+? WHERE payment_id=?',
        [nominal, pen.payment_id]
      );
    }
    await conn.execute(
      `INSERT INTO notifications (notif_id, user_id, tipe, judul, pesan) VALUES (?,?,'penalty_waived','Denda dibebaskan',?)`,
      [uuidv4(), pen.user_id, `Denda Rp${nominal.toLocaleString()} dibebaskan oleh vendor dan dikembalikan ke saldo Anda.`]
    );

    await conn.commit();
    res.json({ success: true, message: 'Denda dibebaskan', data: { refund_amount: nominal } });
  } catch (err) {
    await conn.rollback().catch(() => {});
    res.status(500).json({ success: false, message: err.message });
  } finally {
    conn.release();
  }
});

module.exports = r;
module.exports.checkAndAutoSuspend = checkAndAutoSuspend;
