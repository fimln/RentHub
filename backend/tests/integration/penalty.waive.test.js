const request = require('supertest');
const app = require('../../src/app');
const { query } = require('../../config/database');
const purgeTestData = require('./_purge');
const bcrypt = require('bcrypt');

const validNik = '3271061506870006';
const validSim = 'B-3333333333';

let vehicleId;
let ownerVendorId;
let vendorToken;
let otherVendorId;
let otherVendorToken;

beforeAll(async () => {
  const rows = await query(
    `SELECT v.vehicle_id, v.vendor_id, vn.kontak_email
     FROM vehicles v JOIN vendors vn ON v.vendor_id = vn.vendor_id
     WHERE v.status='available' AND vn.kontak_email IS NOT NULL LIMIT 1`
  );
  if (!rows[0]) {
    throw new Error('Seed DB tidak punya vehicle available dengan vendor ber-email. Jalankan database/seed.sql ke renthub_test.');
  }
  vehicleId = rows[0].vehicle_id;
  ownerVendorId = rows[0].vendor_id;

  const hash = await bcrypt.hash('vendor@123', 10);
  await query('UPDATE vendors SET password_hash=? WHERE vendor_id=?', [hash, ownerVendorId]);
  const loginRes = await request(app)
    .post('/api/auth/login-vendor')
    .send({ email: rows[0].kontak_email, password: 'vendor@123' });
  vendorToken = loginRes.body.data?.access_token;
  if (!vendorToken) throw new Error('Vendor login gagal. Cek seed renthub_test.');

  // Vendor lain (untuk uji akses ditolak). Opsional jika seed cuma 1 vendor.
  const others = await query(
    'SELECT vendor_id, kontak_email FROM vendors WHERE vendor_id != ? AND kontak_email IS NOT NULL LIMIT 1',
    [ownerVendorId]
  );
  if (others[0]) {
    otherVendorId = others[0].vendor_id;
    await query('UPDATE vendors SET password_hash=? WHERE vendor_id=?', [hash, otherVendorId]);
    const otherLogin = await request(app)
      .post('/api/auth/login-vendor')
      .send({ email: others[0].kontak_email, password: 'vendor@123' });
    otherVendorToken = otherLogin.body.data?.access_token;
  }
});

async function cleanup() {
  await purgeTestData(query);
  if (vehicleId) await query("UPDATE vehicles SET status='available' WHERE vehicle_id=?", [vehicleId]);
}

afterAll(async () => {
  await cleanup();
  await query('DELETE FROM refresh_tokens WHERE vendor_id IN (?, ?)', [ownerVendorId, otherVendorId || ownerVendorId]);
});

// Booking lewat waktu -> return menghasilkan penalty 'deducted'. Returns ids.
async function setupBookingWithPenalty(emailSuffix) {
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

  // Mulai 3 hari lalu, durasi 1 hari -> selesai ~2 hari lalu -> overtime saat dikembalikan
  const waktuMulai = new Date(Date.now() - 3 * 86400000).toISOString();
  const bookRes = await request(app)
    .post('/api/bookings')
    .set('Authorization', `Bearer ${token}`)
    .send({ vehicle_id: vehicleId, waktu_mulai: waktuMulai, durasi_hari: 1, metode_pengambilan: 'ambil_sendiri' });
  const bookingId = bookRes.body.data?.booking_id;

  await request(app)
    .post(`/api/bookings/${bookingId}/return`)
    .set('Authorization', `Bearer ${token}`)
    .send({ lat: -7.7972, lng: 110.3688 });

  const penalties = await query(
    'SELECT penalty_id, nominal_denda, status_potong FROM penalties WHERE booking_id=?',
    [bookingId]
  );
  return { userId, token, bookingId, penalty: penalties[0] };
}

async function gopaySaldo(userId) {
  const rows = await query("SELECT saldo FROM ewallet_accounts WHERE user_id=? AND metode_bayar='gopay'", [userId]);
  return parseFloat(rows[0]?.saldo ?? 0);
}

describe('POST /api/vendors/penalties/:penalty_id/waive', () => {
  beforeEach(async () => { await cleanup(); });

  test('TC-WAIVE-001 vendor bebaskan denda -> refund ke penyewa, status waived', async () => {
    const { userId, bookingId, penalty } = await setupBookingWithPenalty('waive001@renthub.id');
    expect(penalty).toBeDefined();
    expect(penalty.status_potong).toBe('deducted');
    const nominal = parseFloat(penalty.nominal_denda);
    expect(nominal).toBeGreaterThan(0);

    const saldoBefore = await gopaySaldo(userId);

    const res = await request(app)
      .post(`/api/vendors/penalties/${penalty.penalty_id}/waive`)
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({});

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const after = await query('SELECT status_potong FROM penalties WHERE penalty_id=?', [penalty.penalty_id]);
    expect(after[0].status_potong).toBe('waived');

    const payment = await query('SELECT refund_amount FROM payments WHERE booking_id=?', [bookingId]);
    expect(parseFloat(payment[0].refund_amount)).toBeGreaterThanOrEqual(nominal);

    expect(await gopaySaldo(userId)).toBeCloseTo(saldoBefore + nominal, 2);

    const refundTxn = await query(
      "SELECT COUNT(*) AS total FROM ewallet_transactions WHERE ref_booking_id=? AND tipe='refund' AND keterangan LIKE 'Pembebasan denda%'",
      [bookingId]
    );
    expect(parseInt(refundTxn[0].total)).toBeGreaterThanOrEqual(1);
  });

  test('TC-WAIVE-002 denda yang sudah dibebaskan tidak bisa dibebaskan lagi -> 400', async () => {
    const { penalty } = await setupBookingWithPenalty('waive002@renthub.id');

    const first = await request(app)
      .post(`/api/vendors/penalties/${penalty.penalty_id}/waive`)
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({});
    expect(first.status).toBe(200);

    const second = await request(app)
      .post(`/api/vendors/penalties/${penalty.penalty_id}/waive`)
      .set('Authorization', `Bearer ${vendorToken}`)
      .send({});
    expect(second.status).toBe(400);
    expect(second.body.success).toBe(false);
  });

  test('TC-WAIVE-003 vendor lain tidak bisa membebaskan denda -> 403', async () => {
    if (!otherVendorToken) return; // seed hanya punya 1 vendor, lewati
    const { penalty } = await setupBookingWithPenalty('waive003@renthub.id');

    const res = await request(app)
      .post(`/api/vendors/penalties/${penalty.penalty_id}/waive`)
      .set('Authorization', `Bearer ${otherVendorToken}`)
      .send({});

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });
});
