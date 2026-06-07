const express = require('express');
const http    = require('http');
const jwt     = require('jsonwebtoken');
const cors    = require('cors');
const { Server } = require('socket.io');
const dotenv = require('dotenv');
const envFile = process.env.NODE_ENV === 'test' ? '.env.test' : '.env';
dotenv.config({ path: envFile });

const app    = express();
const server = http.createServer(app);
const io     = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] }
});

// Simpan io agar bisa diakses dari route handler
app.set('io', io);

app.use(cors());
app.use(express.json());

// Logger
app.use((req, res, next) => {
  const t = new Date().toTimeString().substr(0, 8);
  console.log(`[${t}] ${req.method} ${req.path}`);
  next();
});

// Socket.IO — autentikasi saat connect, masukkan ke room sesuai role
io.on('connection', (socket) => {
  const { token } = socket.handshake.auth;
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    if (decoded.role === 'vendor') {
      socket.join(`vendor:${decoded.vendorId}`);
      console.log(`[Socket] vendor:${decoded.vendorId} connected`);
    } else if (decoded.role === 'user') {
      socket.join(`user:${decoded.userId}`);
      console.log(`[Socket] user:${decoded.userId} connected`);
    } else {
      socket.disconnect(true);
    }
  } catch {
    socket.disconnect(true);
  }

  socket.on('disconnect', () => {
    console.log(`[Socket] ${socket.id} disconnected`);
  });
});

// Routes
app.use('/api/auth',          require('./routes/auth.routes'));
app.use('/api/users',         require('./routes/user.routes'));
app.use('/api/vehicles',      require('./routes/vehicle.routes'));
app.use('/api/bookings',      require('./routes/booking.routes'));
app.use('/api/payments',      require('./routes/payment.routes'));
app.use('/api/geofences',     require('./routes/geofence.routes'));
app.use('/api/iot',           require('./routes/iot.routes'));
app.use('/api/vendors',       require('./routes/vendor.routes'));
app.use('/api/mock',          require('./routes/mock.routes'));
app.use('/api/notifications', require('./routes/notification.routes'));
app.use('/api/reviews',       require('./routes/review.routes'));
app.use('/api/ewallet',       require('./routes/ewallet.routes'));

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'RentHub API berjalan', db: 'MySQL' });
});

// 404
app.use((req, res) => res.status(404).json({ success: false, message: 'Endpoint tidak ditemukan' }));

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err.message);
  res.status(500).json({ success: false, message: err.message || 'Server error' });
});

const PORT = process.env.PORT || 3000;

if (process.env.NODE_ENV !== 'test') {
  server.listen(PORT, () => {
    console.log(`\n🚗 RentHub API Server`);
    console.log(`📡 http://localhost:${PORT}`);
    console.log(`💾 Database: MySQL (XAMPP)\n`);

    const { startTelemetrySimulator } = require('./workers/telemetry.worker');
    startTelemetrySimulator(io);
    console.log('✅ Telemetry simulator aktif');
  });
}

module.exports = app;
