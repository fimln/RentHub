const { query } = require('../../config/database');

async function verifyNik(nik) {
  if (!nik || !/^\d{16}$/.test(nik)) {
    return { valid: false, reason: 'format_invalid' };
  }
  const rows = await query(
    'SELECT nama_lengkap, tanggal_lahir FROM dukcapil_datadiri WHERE nik=?', [nik]
  );
  if (rows.length === 0) {
    return { valid: false, reason: 'not_found' };
  }
  return { valid: true, reason: null, nama_lengkap: rows[0].nama_lengkap, tanggal_lahir: rows[0].tanggal_lahir };
}

async function verifySim(nomor_sim) {
  if (!nomor_sim) {
    return { valid: false, reason: 'format_invalid' };
  }
  const rows = await query(
    'SELECT jenis_sim, tanggal_berlaku, status_aktif FROM korlantas_sim WHERE nomor_sim=?', [nomor_sim]
  );
  if (rows.length === 0 || !rows[0].status_aktif) {
    return { valid: false, reason: 'expired' };
  }
  if (rows[0].jenis_sim !== 'C') {
    return { valid: false, reason: 'wrong_sim_type' };
  }
  return { valid: true, reason: null, tanggal_berlaku: rows[0].tanggal_berlaku };
}

module.exports = { verifyNik, verifySim };
