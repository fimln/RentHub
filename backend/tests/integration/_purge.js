// Shared FK-safe cleanup of all test data (users with email like 'test+%' and
// the test-generated vendor notifications). Deleting in dependency order avoids
// "foreign key constraint fails" when a file inherits leftover rows from a
// previously-run test file. Pass the `query` helper from config/database.
const TEST_USERS = "SELECT user_id FROM users WHERE email LIKE 'test+%'";
const TEST_BOOKINGS = `SELECT booking_id FROM bookings WHERE user_id IN (${TEST_USERS})`;
const TEST_ACCOUNTS = `SELECT account_id FROM ewallet_accounts WHERE user_id IN (${TEST_USERS})`;

module.exports = async function purgeTestData(query) {
  await query(`DELETE FROM reviews WHERE booking_id IN (${TEST_BOOKINGS})`);
  await query(`DELETE FROM unlock_logs WHERE user_id IN (${TEST_USERS})`);
  await query(`DELETE FROM iot_logs WHERE booking_id IN (${TEST_BOOKINGS})`);
  await query(`DELETE FROM trust_logs WHERE user_id IN (${TEST_USERS})`);
  await query(`DELETE FROM penalties WHERE booking_id IN (${TEST_BOOKINGS})`);
  await query(`DELETE FROM payments WHERE booking_id IN (${TEST_BOOKINGS})`);
  await query(`DELETE FROM bookings WHERE user_id IN (${TEST_USERS})`);
  await query(`DELETE FROM ewallet_transactions WHERE account_id IN (${TEST_ACCOUNTS})`);
  await query(`DELETE FROM ewallet_accounts WHERE user_id IN (${TEST_USERS})`);
  await query(`DELETE FROM refresh_tokens WHERE user_id IN (${TEST_USERS})`);
  await query(
    `DELETE FROM notifications WHERE user_id IN (${TEST_USERS})
       OR pesan LIKE 'Booking baru%' OR pesan LIKE 'Kendaraan dikembalikan%'
       OR pesan LIKE 'Kendaraan Disewa%' OR pesan LIKE 'Penyewa membatalkan%'
       OR pesan LIKE '%dibebaskan%'`
  );
  await query(`DELETE FROM users WHERE email LIKE 'test+%'`);
};
