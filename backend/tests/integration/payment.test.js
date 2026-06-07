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

async function cleanupTestData() {
  await query("DELETE FROM reviews WHERE booking_id IN (SELECT booking_id FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM iot_logs WHERE booking_id IN (SELECT booking_id FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM trust_logs WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%')");
  await query("DELETE FROM notifications WHERE pesan LIKE 'test+%' OR pesan LIKE 'Booking baru%' OR pesan LIKE 'Kendaraan dikembalikan%'");
  await query("DELETE FROM penalties WHERE booking_id IN (SELECT booking_id FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM payments WHERE booking_id IN (SELECT booking_id FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM bookings WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%')");
  await query("DELETE FROM ewallet_transactions WHERE account_id IN (SELECT account_id FROM ewallet_accounts WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%'))");
  await query("DELETE FROM refresh_tokens WHERE user_id IN (SELECT user_id FROM users WHERE email LIKE 'test+%')");
  await query("DELETE FROM users WHERE email LIKE 'test+%'");

  if (availableVehicleId) {
    await query("UPDATE vehicles SET status='available' WHERE vehicle_id=?", [availableVehicleId]);
  }
}

async function registerAndLogin(emailSuffix) {
  const email = `test+${emailSuffix}`;
  const regRes = await request(app).post('/api/auth/register').send({
    nama: 'Tester',
    email,
    phone: '081234567890',
    password: 'pass1234',
    nik: validNik,
    nomor_sim: validSim,
  });
  const loginRes = await request(app).post('/api/auth/login').send({
    email,
    password: 'pass1234',
  });
  return {
    userId: regRes.body.data?.user_id,
    token: loginRes.body.data?.access_token,
  };
}

describe('POST /api/bookings (preauth)', () => {
  beforeEach(async () => {
    await cleanupTestData();
  });

  test('TC-PAY-001 preauth sukses (saldo cukup)', async () => {

    const { userId, token } = await registerAndLogin('paypreauth@renthub.id');
    await query('UPDATE users SET saldo_ewallet=2000000 WHERE user_id=?', [userId]);
    await query("UPDATE ewallet_accounts SET saldo=? WHERE user_id=? AND metode_bayar='gopay'", [2000000, userId]);

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({
        vehicle_id: availableVehicleId,
        waktu_mulai: new Date().toISOString(),
        durasi_hari: 1,
        metode_pengambilan: 'ambil_sendiri',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.payment_summary).toBeDefined();

    const payments = await query(
      'SELECT status_payment FROM payments WHERE booking_id=?',
      [res.body.data.booking_id]
    );
    expect(payments[0].status_payment).toBe('pre_authorized');
  });

  test('TC-PAY-002 preauth saldo kurang', async () => {

    const { userId, token } = await registerAndLogin('paypoor@renthub.id');
    await query('UPDATE users SET saldo_ewallet=50 WHERE user_id=?', [userId]);
    await query("UPDATE ewallet_accounts SET saldo=? WHERE user_id=? AND metode_bayar='gopay'", [50, userId]);

    const res = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({
        vehicle_id: availableVehicleId,
        waktu_mulai: new Date().toISOString(),
        durasi_hari: 1,
        metode_pengambilan: 'ambil_sendiri',
      });

    expect(res.status).toBe(402);
    expect(res.body.error.code).toBe('INSUFFICIENT_FUNDS');
  });
});

describe('POST /api/bookings/:id/return (refund)', () => {
  beforeEach(async () => {
    await cleanupTestData();
  });

  test('TC-PAY-003 refund full (kembali tepat waktu)', async () => {

    const { userId, token } = await registerAndLogin('payrefund@renthub.id');
    await query('UPDATE users SET saldo_ewallet=2000000 WHERE user_id=?', [userId]);
    await query("UPDATE ewallet_accounts SET saldo=? WHERE user_id=? AND metode_bayar='gopay'", [2000000, userId]);

    const bookingRes = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({
        vehicle_id: availableVehicleId,
        waktu_mulai: new Date().toISOString(),
        durasi_hari: 1,
        metode_pengambilan: 'ambil_sendiri',
      });

    expect(bookingRes.status).toBe(201);
    const bookingId = bookingRes.body.data.booking_id;

    const returnRes = await request(app)
      .post(`/api/bookings/${bookingId}/return`)
      .set('Authorization', `Bearer ${token}`)
      .send({ lat: -6.2, lng: 106.8 });

    expect(returnRes.status).toBe(200);
    expect(returnRes.body.success).toBe(true);
    expect(returnRes.body.data.deposit_dikembalikan).toBeGreaterThan(0);
    expect(returnRes.body.data.penalty_amount).toBe(0);

    const payments = await query(
      'SELECT status_payment, refund_amount FROM payments WHERE booking_id=?',
      [bookingId]
    );
    expect(payments[0].status_payment).toBe('captured');
    expect(parseFloat(payments[0].refund_amount)).toBeGreaterThan(0);
  });
});
