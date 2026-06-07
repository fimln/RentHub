const express = require('express');
const router = express.Router();
const { query } = require('../../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');
const { v4: uuidv4 } = require('uuid');

// POST /api/reviews — submit review for a completed booking
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { booking_id, rating, komentar } = req.body;
    const user_id = req.user.userId;
    if (!booking_id || !rating || rating < 1 || rating > 5)
      return res.status(400).json({ success: false, message: 'booking_id dan rating (1-5) wajib diisi' });

    const bRows = await query(
      'SELECT booking_id, vehicle_id, status_booking FROM bookings WHERE booking_id=? AND user_id=?',
      [booking_id, user_id]
    );
    if (!bRows[0])
      return res.status(404).json({ success: false, message: 'Booking tidak ditemukan' });
    if (bRows[0].status_booking !== 'completed')
      return res.status(400).json({ success: false, message: 'Hanya booking selesai yang dapat diulas' });

    const existing = await query('SELECT review_id FROM reviews WHERE booking_id=?', [booking_id]);
    if (existing[0])
      return res.status(409).json({ success: false, message: 'Booking ini sudah diulas' });

    const reviewId = uuidv4();
    await query(
      'INSERT INTO reviews (review_id, booking_id, user_id, vehicle_id, rating, komentar) VALUES (?,?,?,?,?,?)',
      [reviewId, booking_id, user_id, bRows[0].vehicle_id, rating, komentar || null]
    );

    await query(
      `UPDATE vehicles SET
         rating_avg   = (SELECT ROUND(AVG(rating), 1) FROM reviews WHERE vehicle_id = vehicles.vehicle_id),
         total_ulasan = (SELECT COUNT(*) FROM reviews WHERE vehicle_id = vehicles.vehicle_id)
       WHERE vehicle_id = ?`,
      [bRows[0].vehicle_id]
    );

    // Agregasi rating ke vendor pemilik (gabungan semua kendaraan vendor)
    await query(
      `UPDATE vendors vn SET
         rating_avg = COALESCE((SELECT ROUND(AVG(r.rating), 1) FROM reviews r
                                JOIN vehicles v ON r.vehicle_id = v.vehicle_id
                                WHERE v.vendor_id = vn.vendor_id), 0),
         total_ulasan = (SELECT COUNT(*) FROM reviews r
                         JOIN vehicles v ON r.vehicle_id = v.vehicle_id
                         WHERE v.vendor_id = vn.vendor_id)
       WHERE vn.vendor_id = (SELECT vendor_id FROM vehicles WHERE vehicle_id = ?)`,
      [bRows[0].vehicle_id]
    );

    res.status(201).json({ success: true, message: 'Ulasan berhasil dikirim', data: { review_id: reviewId } });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// GET /api/reviews/vehicle/:id — public list of reviews for a vehicle
router.get('/vehicle/:id', async (req, res) => {
  try {
    const rows = await query(
      `SELECT r.review_id, r.rating, r.komentar, r.created_at, u.nama AS nama_penyewa
       FROM reviews r JOIN users u ON r.user_id = u.user_id
       WHERE r.vehicle_id = ? ORDER BY r.created_at DESC LIMIT 20`,
      [req.params.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

// GET /api/reviews/booking/:id — check if current user has reviewed this booking
router.get('/booking/:id', authMiddleware, async (req, res) => {
  try {
    const rows = await query(
      'SELECT review_id, rating, komentar, created_at FROM reviews WHERE booking_id=? AND user_id=?',
      [req.params.id, req.user.userId]
    );
    res.json({ success: true, data: rows[0] || null });
  } catch (err) { res.status(500).json({ success: false, message: err.message }); }
});

module.exports = router;
