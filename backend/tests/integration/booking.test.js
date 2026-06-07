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

describe('POST /api/bookings/estimate', () => {
  beforeEach(async () => {
    await cleanupTestData();
  });

  test('TC-BOOK-001 estimate normal', async () => {

    const { token } = await registerAndLogin('bookingest@renthub.id');

    const res = await request(app)
      .post('/api/bookings/estimate')
      .set('Authorization', `Bearer ${token}`)
      .send({
        vehicle_id: availableVehicleId,
        durasi_hari: 2,
        metode_pengambilan: 'ambil_sendiri',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.biaya_sewa).toBeGreaterThan(0);
    expect(res.body.data.total).toBeGreaterThan(0);
  });

  test('TC-BOOK-002 estimate vehicle tidak ada', async () => {
    const { token } = await registerAndLogin('bookingnf@renthub.id');

    const res = await request(app)
      .post('/api/bookings/estimate')
      .set('Authorization', `Bearer ${token}`)
      .send({
        vehicle_id: 'VEH-NOTFOUND-999',
        durasi_jam: 1,
      });

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });
});

describe('POST /api/bookings', () => {
  beforeEach(async () => {
    await cleanupTestData();
  });

  test('TC-BOOK-003 create booking sukses', async () => {

    const { userId, token } = await registerAndLogin('bookingcreate@renthub.id');
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
    expect(res.body.data.booking_id).toBeDefined();
    expect(res.body.data.status_booking).toBe('active');
    expect(res.body.data.payment_summary.total_bayar).toBeGreaterThan(0);

    const payments = await query(
      'SELECT * FROM payments WHERE booking_id=?',
      [res.body.data.booking_id]
    );
    expect(payments.length).toBeGreaterThan(0);
    expect(payments[0].status_payment).toBe('pre_authorized');
  });

  test('TC-BOOK-004 create booking saldo kurang', async () => {

    const { userId, token } = await registerAndLogin('bookingpoor@renthub.id');
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
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('INSUFFICIENT_FUNDS');
  });
});
