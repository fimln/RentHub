const request = require('supertest');
const app = require('../../src/app');
const { query } = require('../../config/database');

const validNik = '3271061506870006';
const validSim = 'B-3333333333';

let availableVehicleId;

beforeAll(async () => {
  const vehicles = await query("SELECT vehicle_id FROM vehicles WHERE status='available' LIMIT 1");
  availableVehicleId = vehicles[0]?.vehicle_id;
  if (!availableVehicleId) {
    throw new Error('Seed DB tidak punya vehicle available. Jalankan database/seed.sql ke renthub_test.');
  }
});

async function cleanup() {
  await query("DELETE FROM reviews WHERE booking_id IN (SELECT booking_id FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM iot_logs WHERE booking_id IN (SELECT booking_id FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM trust_logs WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%')");
  await query("DELETE FROM notifications WHERE pesan LIKE 'Booking baru%' OR pesan LIKE 'Kendaraan dikembalikan%'");
  await query("DELETE FROM penalties WHERE booking_id IN (SELECT booking_id FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM payments WHERE booking_id IN (SELECT booking_id FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%')");
  await query("DELETE FROM ewallet_transactions WHERE account_id IN (SELECT account_id FROM ewallet_accounts WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM ewallet_accounts WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%')");
  await query("DELETE FROM refresh_tokens WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%')");
  await query("DELETE FROM users WHERE email LIKE 'test+%'");
  if (availableVehicleId) {
    await query("UPDATE vehicles SET status='available' WHERE vehicle_id=?", [availableVehicleId]);
  }
}

async function setupCompletedBooking(emailSuffix) {
  const email = `test+${emailSuffix}`;
  const regRes = await request(app).post('/api/auth/register').send({
    nama: 'Tester',
    email,
    phone: '081234567890',
    password: 'pass1234',
    nik: validNik,
    nomor_sim: validSim,
  });
  const userId = regRes.body.data?.user_id;

  await query('UPDATE users SET saldo_ewallet=2000000 WHERE user_id=?', [userId]);
  await query("UPDATE ewallet_accounts SET saldo=2000000 WHERE user_id=? AND metode_bayar='gopay'", [userId]);

  const loginRes = await request(app).post('/api/auth/login').send({ email, password: 'pass1234' });
  const token = loginRes.body.data?.access_token;

  const bookRes = await request(app)
    .post('/api/bookings')
    .set('Authorization', `Bearer ${token}`)
    .send({
      vehicle_id: availableVehicleId,
      waktu_mulai: new Date().toISOString(),
      durasi_hari: 1,
      metode_pengambilan: 'ambil_sendiri',
    });
  const bookingId = bookRes.body.data?.booking_id;

  await request(app)
    .post(`/api/bookings/${bookingId}/return`)
    .set('Authorization', `Bearer ${token}`)
    .send({ lat: -6.2, lng: 106.8 });

  return { userId, token, bookingId };
}

describe('POST /api/reviews', () => {
  beforeEach(async () => { await cleanup(); });

  test('TC-REV-001 submit review pada booking selesai', async () => {
    const { token, bookingId } = await setupCompletedBooking('rev001@renthub.id');

    const res = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${token}`)
      .send({ booking_id: bookingId, rating: 5, komentar: 'Mantap!' });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.review_id).toBeDefined();
  });

  test('TC-REV-002 rating di luar 1-5 ditolak', async () => {
    const { token, bookingId } = await setupCompletedBooking('rev002@renthub.id');

    const res = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${token}`)
      .send({ booking_id: bookingId, rating: 6 });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('TC-REV-003 review kedua pada booking yang sama ditolak (409)', async () => {
    const { token, bookingId } = await setupCompletedBooking('rev003@renthub.id');

    await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${token}`)
      .send({ booking_id: bookingId, rating: 4 });

    const res = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${token}`)
      .send({ booking_id: bookingId, rating: 3 });

    expect(res.status).toBe(409);
  });

  test('TC-REV-004 submit review memperbarui rating_avg kendaraan', async () => {
    const { token, bookingId } = await setupCompletedBooking('rev004@renthub.id');

    await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${token}`)
      .send({ booking_id: bookingId, rating: 4 });

    const rows = await query(
      'SELECT rating_avg, total_ulasan FROM vehicles WHERE vehicle_id=?',
      [availableVehicleId]
    );
    expect(parseFloat(rows[0].rating_avg)).toBeGreaterThan(0);
    expect(parseInt(rows[0].total_ulasan)).toBeGreaterThan(0);
  });
});

describe('GET /api/reviews/vehicle/:id', () => {
  beforeEach(async () => { await cleanup(); });

  test('TC-REV-005 list ulasan kendaraan (public)', async () => {
    const res = await request(app).get(`/api/reviews/vehicle/${availableVehicleId}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });
});

describe('GET /api/reviews/booking/:id', () => {
  beforeEach(async () => { await cleanup(); });

  test('TC-REV-006 cek review booking yang belum diulas mengembalikan null', async () => {
    const { token, bookingId } = await setupCompletedBooking('rev006@renthub.id');

    const res = await request(app)
      .get(`/api/reviews/booking/${bookingId}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toBeNull();
  });

  test('TC-REV-007 cek review setelah submit mengembalikan data review', async () => {
    const { token, bookingId } = await setupCompletedBooking('rev007@renthub.id');

    await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${token}`)
      .send({ booking_id: bookingId, rating: 5, komentar: 'Oke banget' });

    const res = await request(app)
      .get(`/api/reviews/booking/${bookingId}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data).not.toBeNull();
    expect(res.body.data.rating).toBe(5);
  });
});
