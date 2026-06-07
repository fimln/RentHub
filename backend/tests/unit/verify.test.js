const { verifyNik, verifySim } = require('../../src/utils/verify');

// verifyNik/verifySim memverifikasi terhadap dukcapil_datadiri / korlantas_sim,
// jadi butuh seed renthub_test dan harus di-await (fungsinya async).

describe('verifyNik', () => {
  test('TC-VRF-001 NIK valid dari seed dukcapil_datadiri', async () => {
    const result = await verifyNik('3273010101950001');
    expect(result.valid).toBe(true);
    expect(result.reason).toBeNull();
  });

  test('TC-VRF-002 NIK tidak ditemukan di whitelist', async () => {
    const result = await verifyNik('9999999999999999');
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('not_found');
  });

  test('TC-VRF-003 NIK format salah (kurang dari 16 digit)', async () => {
    const result = await verifyNik('12345');
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('format_invalid');
  });

  test('TC-VRF-004 NIK format salah (mengandung huruf)', async () => {
    const result = await verifyNik('327301010195000A');
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('format_invalid');
  });

  test('TC-VRF-005 NIK kosong/null', async () => {
    const result = await verifyNik(null);
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('format_invalid');
  });

  test('TC-VRF-006 NIK string kosong', async () => {
    const result = await verifyNik('');
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('format_invalid');
  });
});

describe('verifySim', () => {
  test('TC-VRF-007 SIM valid (jenis C, aktif) dari seed korlantas_sim', async () => {
    const result = await verifySim('A-9876543210');
    expect(result.valid).toBe(true);
    expect(result.reason).toBeNull();
  });

  test('TC-VRF-008 SIM tidak ditemukan -> expired', async () => {
    const result = await verifySim('X-0000000000');
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('expired');
  });

  test('TC-VRF-009 SIM kosong/null', async () => {
    const result = await verifySim(null);
    expect(result.valid).toBe(false);
    expect(result.reason).toBe('format_invalid');
  });
});
