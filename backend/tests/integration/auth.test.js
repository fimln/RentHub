const request = require('supertest');
const app = require('../../src/app');
const { query } = require('../../config/database');
const purgeTestData = require('./_purge');

const validNik = '3271061506870006';
const validSim = 'B-3333333333';

async function cleanupTestUsers() {
  await purgeTestData(query);
}

describe('POST /api/auth/register', () => {
  beforeEach(cleanupTestUsers);

  test('TC-AUTH-001 register sukses', async () => {
    const res = await request(app).post('/api/auth/register').send({
      nama: 'Tester',
      email: 'test+register@renthub.id',
      phone: '081234567890',
      password: 'pass1234',
      nik: validNik,
      nomor_sim: validSim,
    });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user_id).toBeDefined();
    expect(res.body.data.verified).toBe(true);
    expect(res.body.data.trust_score).toBe(20);
  });

  test('TC-AUTH-002 NIK invalid (tidak ada di whitelist)', async () => {
    const res = await request(app).post('/api/auth/register').send({
      nama: 'Tester',
      email: 'test+nikinvalid@renthub.id',
      phone: '081234567890',
      password: 'pass1234',
      nik: '9999999999999999',
      nomor_sim: validSim,
    });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.data.step).toBe('dukcapil');
  });

  test('TC-AUTH-003 SIM invalid (tidak ada di whitelist)', async () => {
    const res = await request(app).post('/api/auth/register').send({
      nama: 'Tester',
      email: 'test+siminvalid@renthub.id',
      phone: '081234567890',
      password: 'pass1234',
      nik: validNik,
      nomor_sim: 'X-0000000000',
    });
    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.data.step).toBe('korlantas');
  });

  test('TC-AUTH-004 email duplikat', async () => {
    const payload = {
      nama: 'Tester',
      email: 'test+duplicate@renthub.id',
      phone: '081234567890',
      password: 'pass1234',
      nik: validNik,
      nomor_sim: validSim,
    };
    const res1 = await request(app).post('/api/auth/register').send(payload);
    expect(res1.status).toBe(201);

    const res2 = await request(app).post('/api/auth/register').send(payload);
    expect(res2.status).toBe(409);
    expect(res2.body.success).toBe(false);
  });
});

describe('POST /api/auth/login', () => {
  const email = 'test+login@renthub.id';
  const password = 'pass1234';

  beforeEach(async () => {
    await cleanupTestUsers();

    await request(app).post('/api/auth/register').send({
      nama: 'Tester Login',
      email,
      phone: '081234567890',
      password,
      nik: validNik,
      nomor_sim: validSim,
    });
  });

  test('TC-AUTH-005 login sukses', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email,
      password,
    });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.access_token).toBeDefined();
    expect(res.body.data.user).toBeDefined();
  });

  test('TC-AUTH-006 login password salah', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email,
      password: 'salahpassword',
    });
    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });
});
