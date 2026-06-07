const request = require('supertest');
const app = require('../../src/app');
const { query } = require('../../config/database');

const validNik = '3271061506870006';
const validSim = 'B-3333333333';

let vehicleId;
let vendorId;
let originalRating;   // snapshot untuk dikembalikan di afterAll
let originalUlasan;

beforeAll(async () => {
  const rows = await query(
    `SELECT v.vehicle_id, v.vendor_id, vn.rating_avg, vn.total_ulasan
     FROM vehicles v JOIN vendors vn ON v.vendor_id = vn.vendor_id
     WHERE v.status='available' LIMIT 1`
  );
  if (!rows[0]) {
    throw new Error('Seed DB tidak punya vehicle available. Jalankan database/seed.sql ke renthub_test.');
  }
  vehicleId = rows[0].vehicle_id;
  vendorId = rows[0].vendor_id;
  originalRating = rows[0].rating_avg;
  originalUlasan = rows[0].total_ulasan;
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
  if (vehicleId) await query("UPDATE vehicles SET status='available' WHERE vehicle_id=?", [vehicleId]);
}

afterAll(async () => {
  await cleanup();
  // Kembalikan agregat rating vendor ke nilai awal (reviews test sudah dihapus,
  // tapi vendors.rating_avg tidak dihitung ulang otomatis).
  await query('UPDATE vendors SET rating_avg=?, total_ulasan=? WHERE vendor_id=?',
    [originalRating, originalUlasan, vendorId]);
});

async function setupCompletedBooking(emailSuffix) {
  const email = `test+${emailSuffix}`;
  const regRes = await request(app).post('/api/auth/register').send({
    nama: 'Tester', email, phone: '081234567890',
    password: 'pass1234', nik: validNik, nomor_sim: validSim,
  });
  const userId = regRes.body.data?.user_id;

  await query('UPDATE users SET saldo_ewallet=2000000 WHERE user_id=?', [userId]);
  // register sudah membuat akun gopay (saldo 0); cukup set saldonya
  await query("UPDATE ewallet_accounts SET saldo=2000000 WHERE user_id=? AND metode_bayar='gopay'", [userId]);

  const loginRes = await request(app).post('/api/auth/login').send({ email, password: 'pass1234' });
  const token = loginRes.body.data?.access_token;

  const bookRes = await request(app)
    .post('/api/bookings')
    .set('Authorization', `Bearer ${token}`)
    .send({ vehicle_id: vehicleId, waktu_mulai: new Date().toISOString(), durasi_hari: 1, metode_pengambilan: 'ambil_sendiri' });
  const bookingId = bookRes.body.data?.booking_id;

  await request(app)
    .post(`/api/bookings/${bookingId}/return`)
    .set('Authorization', `Bearer ${token}`)
    .send({ lat: -7.7972, lng: 110.3688 });

  return { token, bookingId };
}

describe('POST /api/reviews -> agregasi rating vendor', () => {
  beforeEach(async () => { await cleanup(); });

  test('TC-RATE-001 submit review memperbarui rating_avg vendor', async () => {
    const { token, bookingId } = await setupCompletedBooking('rate001@renthub.id');

    const res = await request(app)
      .post('/api/reviews')
      .set('Authorization', `Bearer ${token}`)
      .send({ booking_id: bookingId, rating: 5, komentar: 'Pelayanan vendor bagus' });
    expect(res.status).toBe(201);

    const vendor = await query('SELECT rating_avg, total_ulasan FROM vendors WHERE vendor_id=?', [vendorId]);
    expect(parseFloat(vendor[0].rating_avg)).toBeGreaterThan(0);
    expect(parseInt(vendor[0].total_ulasan)).toBeGreaterThanOrEqual(1);
  });
});
