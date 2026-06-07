const request = require('supertest');
const app = require('../../src/app');
const { query } = require('../../config/database');
const bcrypt = require('bcrypt');

// ven-003 pakai sub-002 (profesional, maks_armada=20), hanya punya 4 kendaraan
const vendorId = 'ven-003-0000-0000-000000000003';
let vendorToken;
let testVehicleId;

beforeAll(async () => {
  const hash = await bcrypt.hash('vendor@123', 10);
  await query('UPDATE vendors SET password_hash=? WHERE vendor_id=?', [hash, vendorId]);

  const loginRes = await request(app)
    .post('/api/auth/login-vendor')
    .send({ email: 'transjogja@rental.id', password: 'vendor@123' });

  vendorToken = loginRes.body.data?.access_token;
  if (!vendorToken) throw new Error('Vendor login gagal. Cek seed renthub_test.');
});

afterAll(async () => {
  if (testVehicleId) {
    await query('DELETE FROM vehicles WHERE vehicle_id=?', [testVehicleId]);
  }
  await query('DELETE FROM refresh_tokens WHERE vendor_id=?', [vendorId]);
});

describe('GET /api/vendors/fleet', () => {
  test('TC-VEN-001 list armada vendor -> 200 array kendaraan', async () => {
    const res = await request(app)
      .get('/api/vendors/fleet')
      .set('Authorization', `Bearer ${vendorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
  });
});

describe('POST /api/vendors/fleet', () => {
  test('TC-VEN-002 tambah kendaraan baru -> 201 vehicle_id', async () => {
    const res = await request(app)
      .post('/api/vendors/fleet')
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({
        merek: 'Honda',
        model: 'Supra X 125',
        tahun: 2023,
        plat_nomor: 'AB 9999 TEST',
        tarif_per_hari: 80000,
        warna: 'Merah',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.vehicle_id).toBeDefined();
    testVehicleId = res.body.data.vehicle_id;
  });
});

describe('PUT /api/vendors/fleet/:id', () => {
  test('TC-VEN-003 update warna kendaraan -> 200 data terupdate', async () => {
    if (!testVehicleId) return;

    const res = await request(app)
      .put(`/api/vendors/fleet/${testVehicleId}`)
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({ warna: 'Biru' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.warna).toBe('Biru');
  });
});

describe('DELETE /api/vendors/fleet/:id', () => {
  test('TC-VEN-004 nonaktifkan kendaraan -> 200 status inactive', async () => {
    if (!testVehicleId) return;

    const res = await request(app)
      .delete(`/api/vendors/fleet/${testVehicleId}`)
      .set('Authorization', `Bearer ${vendorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const rows = await query('SELECT status FROM vehicles WHERE vehicle_id=?', [testVehicleId]);
    expect(rows[0]?.status).toBe('inactive');
  });
});

describe('GET /api/vendors/dashboard', () => {
  test('TC-VEN-005 dashboard vendor -> 200 stats tersedia', async () => {
    const res = await request(app)
      .get('/api/vendors/dashboard')
      .set('Authorization', `Bearer ${vendorToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toBeDefined();
  });
});
