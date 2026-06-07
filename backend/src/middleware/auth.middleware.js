const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  const auth = req.headers['authorization'];
  if (!auth || !auth.startsWith('Bearer '))
    return res.status(401).json({ success: false, message: 'Token tidak ditemukan' });
  try {
    req.user = jwt.verify(auth.split(' ')[1], process.env.JWT_SECRET);
    next();
  } catch {
    res.status(401).json({ success: false, message: 'Token tidak valid atau kedaluwarsa' });
  }
};

// Alias lama — digunakan di vendor.routes.js & notification.routes.js
const vendorMiddleware = (req, res, next) => {
  const auth = req.headers['authorization'];
  if (!auth || !auth.startsWith('Bearer '))
    return res.status(401).json({ success: false, message: 'Token tidak ditemukan' });
  try {
    const decoded = jwt.verify(auth.split(' ')[1], process.env.JWT_SECRET);
    if (decoded.role !== 'vendor')
      return res.status(403).json({ success: false, message: 'Akses hanya untuk vendor' });
    req.vendor = decoded;
    next();
  } catch {
    res.status(401).json({ success: false, message: 'Token tidak valid' });
  }
};

// Nama baru sesuai plan — menyimpan decoded ke req.user agar konsisten
const vendorAuthMiddleware = (req, res, next) => {
  const auth = req.headers['authorization'];
  if (!auth || !auth.startsWith('Bearer '))
    return res.status(401).json({ success: false, message: 'Token tidak ditemukan' });
  try {
    const decoded = jwt.verify(auth.split(' ')[1], process.env.JWT_SECRET);
    if (decoded.role !== 'vendor')
      return res.status(403).json({ success: false, message: 'Akses vendor diperlukan' });
    req.user = decoded;
    next();
  } catch {
    res.status(401).json({ success: false, message: 'Token tidak valid' });
  }
};

module.exports = { authMiddleware, vendorMiddleware, vendorAuthMiddleware };
