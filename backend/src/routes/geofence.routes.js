// geofence.routes.js
const express = require('express');
const router = express.Router();
const { query } = require('../../config/database');

router.get('/', async (req, res) => {
  try {
    const rows = await query('SELECT * FROM geofences WHERE is_active=1 ORDER BY tipe, nama_lokasi');
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

router.post('/validate', async (req, res) => {
  try {
    const { geofence_id, lat, lng } = req.body;
    const rows = await query('SELECT * FROM geofences WHERE geofence_id=?', [geofence_id]);
    if (!rows[0]) return res.status(404).json({ success: false, message: 'Geofence tidak ditemukan' });
    const g = rows[0];
    const R = 6371000;
    const dLat = (parseFloat(lat) - g.latitude) * Math.PI / 180;
    const dLng = (parseFloat(lng) - g.longitude) * Math.PI / 180;
    const distance = Math.round(R * Math.sqrt(dLat * dLat + dLng * dLng));
    res.json({ success: true, valid: distance <= g.radius_meter, distance_meter: distance, radius_meter: g.radius_meter });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;
