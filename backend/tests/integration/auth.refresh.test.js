const request = require('supertest');
const app = require('../../src/app');
const { query } = require('../../config/database');
const purgeTestData = require('./_purge');

const validNik = '3271061506870006';
const validSim = 'B-3333333333';

async function registerAndLogin(emailSuffix) {
  const email = `test+${emailSuffix}`;
  await request(app).post('/api/auth/register').send({
    nama: 'Tester',
    email,
    phone: '081234567890',
    password: 'pass1234',
    nik: validNik,
    nomor_sim: validSim,
  });
  const loginRes = await request(app).post('/api/auth/login').send({ email, password: 'pass1234' });
  return {
    token: loginRes.body.data?.access_token,
    refreshToken: loginRes.body.data?.refresh_token,
  };
}

async function cleanup() {
  await purgeTestData(query);
}

describe('POST /api/auth/refresh', () => {
  beforeAll(async () => { await cleanup(); });
  afterEach(async () => { await cleanup(); });

  test('TC-AUTH-007 refresh dengan token valid -> 200 access_token baru', async () => {
    const { refreshToken } = await registerAndLogin('refresh001@renthub.id');

    const res = await request(app)
      .post('/api/auth/refresh')
      .send({ refresh_token: refreshToken });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.access_token).toBeDefined();
    expect(res.body.data.refresh_token).toBeDefined();
    expect(res.body.data.refresh_token).not.toBe(refreshToken);
  });

  test('TC-AUTH-008 refresh dengan token string tidak valid -> 401', async () => {
    const res = await request(app)
      .post('/api/auth/refresh')
      .send({ refresh_token: 'token.invalid.sekali' });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  test('TC-AUTH-009 refresh rotation: token lama tidak bisa dipakai ulang -> 401', async () => {
    const { refreshToken: oldToken } = await registerAndLogin('refresh003@renthub.id');

    const rotateRes = await request(app)
      .post('/api/auth/refresh')
      .send({ refresh_token: oldToken });
    expect(rotateRes.status).toBe(200);

    const retryRes = await request(app)
      .post('/api/auth/refresh')
      .send({ refresh_token: oldToken });

    expect(retryRes.status).toBe(401);
    expect(retryRes.body.success).toBe(false);
  });

  test('TC-AUTH-010 refresh tanpa body (tanpa refresh_token) -> 400', async () => {
    const res = await request(app)
      .post('/api/auth/refresh')
      .send({});

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });
});
