const request = require('supertest');
const app = require('../../src/app');
const { query } = require('../../config/database');
const purgeTestData = require('./_purge');

const validNik = '3271061506870006';
const validSim = 'B-3333333333';

async function cleanup() {
  await purgeTestData(query);
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

  const loginRes = await request(app).post('/api/auth/login').send({ email, password: 'pass1234' });
  return { userId, token: loginRes.body.data?.access_token };
}

describe('POST /api/ewallet/topup', () => {
  beforeEach(async () => { await cleanup(); });

  test('TC-EWL-001 topup sukses menambah saldo', async () => {
    const saldoAwal = 100000;
    const { userId, token } = await setupUserWithEwallet('ewl001@renthub.id', saldoAwal);

    const res = await request(app)
      .post('/api/ewallet/topup')
      .set('Authorization', `Bearer ${token}`)
      .send({ metode_bayar: 'gopay', amount: 50000 });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.saldo_baru).toBe(150000);

    const rows = await query(
      "SELECT saldo FROM ewallet_accounts WHERE user_id=? AND metode_bayar='gopay'",
      [userId]
    );
    expect(parseFloat(rows[0].saldo)).toBe(150000);
  });

  test('TC-EWL-002 topup menulis baris ewallet_transactions tipe topup', async () => {
    const { userId, token } = await setupUserWithEwallet('ewl002@renthub.id', 0);

    await request(app)
      .post('/api/ewallet/topup')
      .set('Authorization', `Bearer ${token}`)
      .send({ metode_bayar: 'gopay', amount: 25000 });

    const txns = await query(
      `SELECT tipe, amount FROM ewallet_transactions
       WHERE account_id = (SELECT account_id FROM ewallet_accounts WHERE user_id=? AND metode_bayar='gopay')
       ORDER BY created_at DESC LIMIT 1`,
      [userId]
    );
    expect(txns[0].tipe).toBe('topup');
    expect(parseFloat(txns[0].amount)).toBe(25000);
  });

  test('TC-EWL-003 topup amount 0 atau negatif ditolak', async () => {
    const { token } = await setupUserWithEwallet('ewl003@renthub.id', 0);

    const res = await request(app)
      .post('/api/ewallet/topup')
      .set('Authorization', `Bearer ${token}`)
      .send({ metode_bayar: 'gopay', amount: 0 });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  test('TC-EWL-004 topup metode tidak terdaftar ditolak (404)', async () => {
    const { token } = await setupUserWithEwallet('ewl004@renthub.id', 0);

    // register otomatis membuat semua metode standar, jadi pakai metode di luar daftar
    const res = await request(app)
      .post('/api/ewallet/topup')
      .set('Authorization', `Bearer ${token}`)
      .send({ metode_bayar: 'paypal', amount: 10000 });

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  test('TC-EWL-005 topup memperbarui users.saldo_ewallet', async () => {
    const { userId, token } = await setupUserWithEwallet('ewl005@renthub.id', 0);

    await request(app)
      .post('/api/ewallet/topup')
      .set('Authorization', `Bearer ${token}`)
      .send({ metode_bayar: 'gopay', amount: 75000 });

    const rows = await query('SELECT saldo_ewallet FROM users WHERE user_id=?', [userId]);
    expect(parseFloat(rows[0].saldo_ewallet)).toBe(75000);
  });
});

describe('GET /api/ewallet/transactions', () => {
  beforeEach(async () => { await cleanup(); });

  test('TC-EWL-006 list transaksi mengembalikan array', async () => {
    const { token } = await setupUserWithEwallet('ewl006@renthub.id', 0);

    const res = await request(app)
      .get('/api/ewallet/transactions')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  test('TC-EWL-007 list transaksi setelah topup menampilkan entri', async () => {
    const { token } = await setupUserWithEwallet('ewl007@renthub.id', 0);

    await request(app)
      .post('/api/ewallet/topup')
      .set('Authorization', `Bearer ${token}`)
      .send({ metode_bayar: 'gopay', amount: 10000 });

    const res = await request(app)
      .get('/api/ewallet/transactions')
      .set('Authorization', `Bearer ${token}`);

    expect(res.body.data.length).toBeGreaterThan(0);
    expect(res.body.data[0].tipe).toBe('topup');
  });

  test('TC-EWL-008 filter metode_bayar ovo tidak menampilkan transaksi gopay', async () => {
    const { token } = await setupUserWithEwallet('ewl008@renthub.id', 0);

    await request(app)
      .post('/api/ewallet/topup')
      .set('Authorization', `Bearer ${token}`)
      .send({ metode_bayar: 'gopay', amount: 10000 });

    const res = await request(app)
      .get('/api/ewallet/transactions?metode_bayar=ovo')
      .set('Authorization', `Bearer ${token}`);

    expect(res.status).toBe(200);
    expect(res.body.data.length).toBe(0);
  });
});
