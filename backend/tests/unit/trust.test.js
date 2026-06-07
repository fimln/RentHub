const { levelFromScore } = require('../../src/utils/trust');

describe('levelFromScore', () => {
  test('TC-TRUST-001 score 49 -> bronze (batas bawah silver)', () => {
    expect(levelFromScore(49)).toBe('bronze');
  });

  test('TC-TRUST-002 score 50 -> silver (batas bawah silver)', () => {
    expect(levelFromScore(50)).toBe('silver');
  });

  test('TC-TRUST-003 score 74 -> silver (batas atas silver)', () => {
    expect(levelFromScore(74)).toBe('silver');
  });

  test('TC-TRUST-004 score 75 -> gold (batas bawah gold)', () => {
    expect(levelFromScore(75)).toBe('gold');
  });

  test('TC-TRUST-005 score 89 -> gold (batas atas gold)', () => {
    expect(levelFromScore(89)).toBe('gold');
  });

  test('TC-TRUST-006 score 90 -> platinum (batas bawah platinum)', () => {
    expect(levelFromScore(90)).toBe('platinum');
  });

  test('TC-TRUST-007 score 100 -> platinum', () => {
    expect(levelFromScore(100)).toBe('platinum');
  });

  test('TC-TRUST-008 score 0 -> bronze', () => {
    expect(levelFromScore(0)).toBe('bronze');
  });
});
