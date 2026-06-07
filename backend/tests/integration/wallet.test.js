const request = require('supertest');
const app = require('../../src/app');
const { query } = require('../../config/database');
const purgeTestData = require('./_purge');

const validNik = '3271061506870006';
const validSim = 'B-3333333333';

let availableVehicleId;

beforeAll(async () => {
  // Bersihkan sisa test user dari file test sebelumnya (NIK unique constraint)
  await purgeTestData(query);

  const vehicles = await query("SELECT vehicle_id FROM vehicles WHERE status='available' LIMIT 1");
  availableVehicleId = vehicles[0]?.vehicle_id;
  if (!availableVehicleId) {
    throw new Error('Seed DB tidak punya vehicle available. Jalankan database/seed.sql ke renthub_test.');
  }
});

async function cleanup() {
  await purgeTestData(query);
  if (availableVehicleId) {
    await query("UPDATE vehicles SET status='available' WHERE vehicle_id=?", [availableVehicleId]);
  }
}

async function setupUserWithEwallet(emailSuffix, saldo) {
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
  await query("UPDATE ewallet_accounts SET saldo=? WHERE user_id=? AND metode_bayar='gopay'", [saldo, userId]);

  const loginRes = await request(app)
    .post('/api/auth/login')
    .send({ email, password: 'pass1234' });
  return { userId, token: loginRes.body.data?.access_token };
}

describe('Wallet deduction integration', () => {
  beforeEach(async () => { await cleanup(); });

  test('TC-WAL-001 booking sukses -> ewallet_accounts.saldo gopay berkurang', async () => {
    const saldoAwal = 2000000;
    const { userId, token } = await setupUserWithEwallet('wal001@renthub.id', saldoAwal);

    const bookRes = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({
        vehicle_id: availableVehicleId,
        waktu_mulai: new Date().toISOString(),
        durasi_hari: 1,
        metode_bayar: 'gopay',
        metode_pengambilan: 'ambil_sendiri',
      });

    expect(bookRes.status).toBe(201);

    const rows = await query(
      "SELECT saldo FROM ewallet_accounts WHERE user_id=? AND metode_bayar='gopay'",
      [userId]
    );
    expect(parseFloat(rows[0].saldo)).toBeLessThan(saldoAwal);
  });

  test('TC-WAL-002 booking sukses -> users.saldo_ewallet berkurang sesuai total_bayar', async () => {
    const saldoAwal = 2000000;
    const { userId, token } = await setupUserWithEwallet('wal002@renthub.id', saldoAwal);

    const bookRes = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({
        vehicle_id: availableVehicleId,
        waktu_mulai: new Date().toISOString(),
        durasi_hari: 1,
        metode_bayar: 'gopay',
        metode_pengambilan: 'ambil_sendiri',
      });

    expect(bookRes.status).toBe(201);
    const totalBayar = bookRes.body.data.payment_summary.total_bayar;

    const rows = await query('SELECT saldo_ewallet FROM users WHERE user_id=?', [userId]);
    expect(parseFloat(rows[0].saldo_ewallet)).toBeCloseTo(saldoAwal - totalBayar, 0);
  });

  test('TC-WAL-003 return tepat waktu -> saldo dikembalikan ke users.saldo_ewallet', async () => {
    const saldoAwal = 2000000;
    const { userId, token } = await setupUserWithEwallet('wal003@renthub.id', saldoAwal);

    const bookRes = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({
        vehicle_id: availableVehicleId,
        waktu_mulai: new Date().toISOString(),
        durasi_hari: 1,
        metode_bayar: 'gopay',
        metode_pengambilan: 'ambil_sendiri',
      });
    expect(bookRes.status).toBe(201);
    const bookingId = bookRes.body.data.booking_id;

    const afterBooking = parseFloat(
      (await query('SELECT saldo_ewallet FROM users WHERE user_id=?', [userId]))[0].saldo_ewallet
    );

    await request(app)
      .post(`/api/bookings/${bookingId}/return`)
      .set('Authorization', `Bearer ${token}`)
      .send({ lat: -6.2, lng: 106.8 });

    const afterReturn = parseFloat(
      (await query('SELECT saldo_ewallet FROM users WHERE user_id=?', [userId]))[0].saldo_ewallet
    );
    expect(afterReturn).toBeGreaterThan(afterBooking);
  });

  test('TC-WAL-004 GET /api/users/profile setelah booking -> saldo_ewallet di API berkurang', async () => {
    const saldoAwal = 2000000;
    const { token } = await setupUserWithEwallet('wal004@renthub.id', saldoAwal);

    await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${token}`)
      .send({
        vehicle_id: availableVehicleId,
        waktu_mulai: new Date().toISOString(),
        durasi_hari: 1,
        metode_bayar: 'gopay',
        metode_pengambilan: 'ambil_sendiri',
      });

    const profileRes = await request(app)
      .get('/api/users/profile')
      .set('Authorization', `Bearer ${token}`);

    expect(profileRes.status).toBe(200);
    expect(parseFloat(profileRes.body.data.saldo_ewallet)).toBeLessThan(saldoAwal);
  });
});
