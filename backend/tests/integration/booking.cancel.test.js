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
  await query("DELETE FROM unlock_logs WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%')");
  await query("DELETE FROM iot_logs WHERE booking_id IN (SELECT booking_id FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM trust_logs WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%')");
  await query("DELETE FROM notifications WHERE pesan LIKE 'Booking baru%' OR pesan LIKE 'Penyewa membatalkan%'");
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

// register + fund gopay + login + create booking. Returns ids + token.
async function createPaidBooking(emailSuffix, { saldo = 2000000 } = {}) {
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

  await query('UPDATE users SET saldo_ewallet=? WHERE user_id=?', [saldo, userId]);
  // register sudah membuat akun gopay (saldo 0); cukup set saldonya
  await query("UPDATE ewallet_accounts SET saldo=? WHERE user_id=? AND metode_bayar='gopay'", [saldo, userId]);

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

  return {
    userId,
    token,
    bookingId: bookRes.body.data?.booking_id,
    unlockToken: bookRes.body.data?.unlock_token,
    totalBayar: bookRes.body.data?.payment_summary?.total_bayar,
  };
}

async function gopaySaldo(userId) {
  const rows = await query(
    "SELECT saldo FROM ewallet_accounts WHERE user_id=? AND metode_bayar='gopay'",
    [userId]
  );
  return parseFloat(rows[0]?.saldo ?? 0);
}

describe('POST /api/bookings/:id/cancel', () => {
  beforeEach(async () => { await cleanup(); });

  test('TC-CANCEL-001 batalkan booking aktif -> refund penuh, kendaraan tersedia', async () => {
    const { userId, token, bookingId } = await createPaidBooking('cancel001@renthub.id');

    const res = await request(app)
      .post(`/api/bookings/${bookingId}/cancel`)
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const booking = await query('SELECT status_booking FROM bookings WHERE booking_id=?', [bookingId]);
    expect(booking[0].status_booking).toBe('cancelled');

    const payment = await query('SELECT status_payment, refund_amount, total_bayar FROM payments WHERE booking_id=?', [bookingId]);
    expect(payment[0].status_payment).toBe('refunded');
    expect(parseFloat(payment[0].refund_amount)).toBe(parseFloat(payment[0].total_bayar));

    const vehicle = await query('SELECT status FROM vehicles WHERE vehicle_id=?', [availableVehicleId]);
    expect(vehicle[0].status).toBe('available');

    // Deduct penuh saat booking lalu refund penuh saat cancel -> saldo kembali utuh
    expect(await gopaySaldo(userId)).toBe(2000000);
  });

  test('TC-CANCEL-002 tidak bisa batal setelah kendaraan dibuka -> 409', async () => {
    const { token, bookingId, unlockToken } = await createPaidBooking('cancel002@renthub.id');

    const unlockRes = await request(app)
      .post('/api/iot/unlock')
      .set('Authorization', `Bearer ${token}`)
      .send({ booking_id: bookingId, aksi: 'unlock', unlock_token: unlockToken });
    expect(unlockRes.status).toBe(200);

    const res = await request(app)
      .post(`/api/bookings/${bookingId}/cancel`)
      .set('Authorization', `Bearer ${token}`)
      .send({});

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);

    const booking = await query('SELECT status_booking FROM bookings WHERE booking_id=?', [bookingId]);
    expect(booking[0].status_booking).toBe('active');
  });

  test('TC-CANCEL-003 batal pada booking non-aktif -> 400', async () => {
    const { token, bookingId } = await createPaidBooking('cancel003@renthub.id');

    const first = await request(app)
      .post(`/api/bookings/${bookingId}/cancel`)
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(first.status).toBe(200);

    const second = await request(app)
      .post(`/api/bookings/${bookingId}/cancel`)
      .set('Authorization', `Bearer ${token}`)
      .send({});
    expect(second.status).toBe(400);
    expect(second.body.success).toBe(false);
  });
});
