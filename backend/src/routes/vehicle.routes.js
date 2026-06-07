const express = require('express');
const router  = express.Router();
const { query } = require('../../config/database');

// GET /api/vehicles
router.get('/', async (req, res) => {
  try {
    const { jenis, status } = req.query;
    let sql = `
      SELECT v.vehicle_id, v.vendor_id, v.jenis, v.merek, v.model, v.tahun, v.plat_nomor,
             v.warna, v.status, v.tarif_per_jam, v.tarif_per_hari, v.tarif_deposit, v.kapasitas,
             v.foto_url, v.deskripsi, v.fitur, v.lokasi_lat, v.lokasi_lng,
             v.rating_avg, v.total_ulasan,
             vn.nama_vendor, vn.kota, vn.rating_avg AS vendor_rating, vn.total_ulasan AS vendor_total_ulasan
      FROM vehicles v
      JOIN vendors vn ON v.vendor_id = vn.vendor_id
      WHERE 1=1
    `;
    const params = [];
    if (jenis)  { sql += ' AND v.jenis=?'; params.push(jenis); }
    if (status) { sql += ' AND v.status=?'; params.push(status); }
    else        { sql += " AND v.status != 'inactive'"; }
    sql += ' ORDER BY (v.status="available") DESC, v.rating_avg DESC';

    const rows = await query(sql, params);
    // Parse JSON fitur
    rows.forEach(r => { try { r.fitur = JSON.parse(r.fitur || '[]'); } catch { r.fitur = []; } });
    res.json({ success: true, data: rows, total: rows.length });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/vehicles/:id
router.get('/:id', async (req, res) => {
  try {
    const rows = await query(
      `SELECT v.*, vn.nama_vendor, vn.kontak_phone, vn.rating_avg AS vendor_rating
       FROM vehicles v JOIN vendors vn ON v.vendor_id = vn.vendor_id
       WHERE v.vehicle_id=?`, [req.params.id]
    );
    if (!rows[0]) return res.status(404).json({ success: false, message: 'Kendaraan tidak ditemukan' });
    const v = rows[0];
    try { v.fitur = JSON.parse(v.fitur || '[]'); } catch { v.fitur = []; }

    const iot = await query(
      `SELECT status_mesin, status_kunci, lokasi_lat, lokasi_lng, kecepatan, waktu_update
       FROM iot_logs WHERE vehicle_id=? ORDER BY waktu_update DESC LIMIT 1`, [req.params.id]
    );
    v.iot_status = iot[0] || null;
    res.json({ success: true, data: v });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
