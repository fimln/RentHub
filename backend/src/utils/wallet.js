const { v4: uuidv4 } = require('uuid');

async function deduct(conn, { userId, metodeBayar, amount, refBookingId = null, keterangan = '', tipe = 'deduct' }) {
  const [rows] = await conn.execute(
    'SELECT account_id, saldo FROM ewallet_accounts WHERE user_id=? AND metode_bayar=? FOR UPDATE',
    [userId, metodeBayar]
  );
  if (!rows[0]) {
    const e = new Error(`Metode bayar ${metodeBayar} tidak ditemukan untuk user`);
    e.code = 'METHOD_NOT_FOUND';
    throw e;
  }
  const before = parseFloat(rows[0].saldo);
  if (before < amount) {
    const e = new Error('Saldo metode bayar tidak mencukupi');
    e.code = 'INSUFFICIENT_FUNDS';
    throw e;
  }
  const after = before - amount;
  await conn.execute('UPDATE ewallet_accounts SET saldo=? WHERE account_id=?', [after, rows[0].account_id]);
  await conn.execute(
    'UPDATE users SET saldo_ewallet=(SELECT COALESCE(SUM(saldo),0) FROM ewallet_accounts WHERE user_id=?) WHERE user_id=?',
    [userId, userId]
  );
  await conn.execute(
    `INSERT INTO ewallet_transactions (txn_id, account_id, tipe, amount, saldo_sebelum, saldo_sesudah, ref_booking_id, keterangan)
     VALUES (?,?,?,?,?,?,?,?)`,
    [uuidv4(), rows[0].account_id, tipe, amount, before, after, refBookingId, keterangan]
  );
  return after;
}

async function credit(conn, { userId, metodeBayar, amount, refBookingId = null, keterangan = '', tipe = 'refund' }) {
  const [rows] = await conn.execute(
    'SELECT account_id, saldo FROM ewallet_accounts WHERE user_id=? AND metode_bayar=? FOR UPDATE',
    [userId, metodeBayar]
  );
  if (!rows[0]) {
    const e = new Error(`Metode bayar ${metodeBayar} tidak ditemukan untuk user`);
    e.code = 'METHOD_NOT_FOUND';
    throw e;
  }
  const before = parseFloat(rows[0].saldo);
  const after = before + amount;
  await conn.execute('UPDATE ewallet_accounts SET saldo=? WHERE account_id=?', [after, rows[0].account_id]);
  await conn.execute(
    'UPDATE users SET saldo_ewallet=(SELECT COALESCE(SUM(saldo),0) FROM ewallet_accounts WHERE user_id=?) WHERE user_id=?',
    [userId, userId]
  );
  await conn.execute(
    `INSERT INTO ewallet_transactions (txn_id, account_id, tipe, amount, saldo_sebelum, saldo_sesudah, ref_booking_id, keterangan)
     VALUES (?,?,?,?,?,?,?,?)`,
    [uuidv4(), rows[0].account_id, tipe, amount, before, after, refBookingId, keterangan]
  );
  return after;
}

module.exports = { deduct, credit };
