const request = require('supertest');
const app = require('../../src/app');
const { query } = require('../../config/database');
const purgeTestData = require('./_purge');
const bcrypt = require('bcrypt');

const validNik = '3271061506870006';
const validSim = 'B-3333333333';
const vendorId = 'ven-003-0000-0000-000000000003';

// veh-008 (ven-003) tidak dipakai test lain, selalu available di seed
const targetVehicleId = 'veh-008';

let userToken;
let vendorToken;

beforeAll(async () => {
  // Bersihkan sisa test user dari file test sebelumnya (NIK unique constraint)
  await purgeTestData(query);

  // Pastikan target vehicle available
  await query("UPDATE vehicles SET status='available' WHERE vehicle_id=?", [targetVehicleId]);

  // Setup vendor ven-003
  const hash = await bcrypt.hash('vendor@123', 10);
  await query('UPDATE vendors SET password_hash=? WHERE vendor_id=?', [hash, vendorId]);
  const vRes = await request(app)
    .post('/api/auth/login-vendor')
    .send({ email: 'transjogja@rental.id', password: 'vendor@123' });
  vendorToken = vRes.body.data?.access_token;
  if (!vendorToken) throw new Error('Vendor login gagal.');

  // Setup user renter
  const email = 'test+notif001@renthub.id';
  await request(app).post('/api/auth/register').send({
    nama: 'Tester Notif',
    email,
    phone: '081234567890',
    password: 'pass1234',
    nik: validNik,
    nomor_sim: validSim,
  });
  await query("UPDATE users SET saldo_ewallet=2000000 WHERE email=?", [email]);
  await query("UPDATE ewallet_accounts SET saldo=2000000 WHERE metode_bayar='gopay' AND user_id=(SELECT user_id FROM users WHERE email=?)", [email]);
  const uRes = await request(app).post('/api/auth/login').send({ email, password: 'pass1234' });
  userToken = uRes.body.data?.access_token;
  if (!userToken) throw new Error('User login gagal.');
});

afterAll(async () => {
  await purgeTestData(query);
  await query('DELETE FROM refresh_tokens WHERE vendor_id=?', [vendorId]);
  await query("UPDATE vehicles SET status='available' WHERE vehicle_id=?", [targetVehicleId]);
});

describe('GET /api/notifications', () => {
  test('TC-NOTIF-001 user authenticated -> 200 returns array', async () => {
    const res = await request(app)
      .get('/api/notifications')
      .set('Authorization', `Bearer ${userToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  test('TC-NOTIF-003 tanpa token -> 401', async () => {
    const res = await request(app).get('/api/notifications');
    expect(res.status).toBe(401);
  });
});

describe('Vendor notification setelah booking', () => {
  test('TC-NOTIF-002 booking sukses -> GET /api/notifications/vendor ada notifikasi vehicle_rented', async () => {
    const bookRes = await request(app)
      .post('/api/bookings')
      .set('Authorization', `Bearer ${userToken}`)
      .send({
        vehicle_id: targetVehicleId,
        waktu_mulai: new Date().toISOString(),
        durasi_hari: 1,
        metode_bayar: 'gopay',
        metode_pengambilan: 'ambil_sendiri',
      });

    expect(bookRes.status).toBe(201);

    const res = await request(app)
      .get('/api/notifications/vendor')
      .set('Authorization', `Bearer ${vendorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    const vehicleRented = res.body.data.find(n => n.tipe === 'vehicle_rented');
    expect(vehicleRented).toBeDefined();
  });
});
