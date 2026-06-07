const { query } = require('../../config/database');

function startTelemetrySimulator(io) {
  setInterval(async () => {
    try {
      const activeBookings = await query(
        `SELECT b.booking_id, b.vehicle_id, v.vendor_id, v.lokasi_lat, v.lokasi_lng
         FROM bookings b
         JOIN vehicles v ON b.vehicle_id = v.vehicle_id
         WHERE b.status_booking = 'active'`
      );

      for (const b of activeBookings) {
        const lat   = (parseFloat(b.lokasi_lat)  || -7.7972)  + (Math.random() - 0.5) * 0.0005;
        const lng   = (parseFloat(b.lokasi_lng)  || 110.3688) + (Math.random() - 0.5) * 0.0005;
        const speed = Math.round(Math.random() * 30);

        await query(
          'UPDATE vehicles SET lokasi_lat=?, lokasi_lng=? WHERE vehicle_id=?',
          [lat, lng, b.vehicle_id]
        );

        io.to(`vendor:${b.vendor_id}`).emit('vehicle:update', {
          vehicle_id:  b.vehicle_id,
          lokasi_lat:  lat,
          lokasi_lng:  lng,
          kecepatan:   speed,
          status_kunci: 'unlocked',
          status_mesin: 'on',
          timestamp:   new Date().toISOString(),
        });
      }
    } catch (err) {
      console.error('[Telemetry] Error:', err.message);
    }
  }, 10000);
}

module.exports = { startTelemetrySimulator };
