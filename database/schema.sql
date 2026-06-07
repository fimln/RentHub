-- ============================================================
-- RENTHUB - DATABASE SCHEMA (MySQL 8.0)
-- Universitas Gadjah Mada | PPL 2026
-- ============================================================
-- Cara pakai:
--   1. Buka phpMyAdmin (http://localhost/phpmyadmin)
--   2. Buat database target jika belum ada (renthub_db untuk dev,
--      renthub_test untuk test)
--   3. Pilih database target -> tab SQL -> paste seluruh isi file ini -> Go
-- File ini tidak meng-hardcode nama database; target ditentukan
-- dari database yang dipilih di phpMyAdmin.
-- ============================================================

-- ============================================================
-- SIMULASI DATABASE EKSTERNAL
-- Prefix: dukcapil_, korlantas_, ewallet_
-- ============================================================

CREATE TABLE dukcapil_datadiri (
    nik             VARCHAR(16) PRIMARY KEY,
    nama_lengkap    VARCHAR(150) NOT NULL,
    tanggal_lahir   DATE NOT NULL
) ENGINE=InnoDB;

CREATE TABLE korlantas_sim (
    nomor_sim        VARCHAR(30) PRIMARY KEY,
    nama_lengkap     VARCHAR(150) NOT NULL,
    jenis_sim        ENUM('A','BI','BII','C','D') NOT NULL DEFAULT 'C',
    tanggal_berlaku  DATE NOT NULL,
    status_aktif     TINYINT(1) DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE korlantas_kendaraan (
    nomor_plat            VARCHAR(15) PRIMARY KEY,
    nomor_stnk            VARCHAR(50) UNIQUE NOT NULL,
    tanggal_berlaku_stnk  DATE NOT NULL,
    bukti_pajak_url       VARCHAR(500),
    status_aktif          TINYINT(1) DEFAULT 1
) ENGINE=InnoDB;

-- ============================================================
-- TABEL REFERENSI LANGGANAN VENDOR
-- ============================================================

CREATE TABLE vendor_subscriptions (
    subscription_id  VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    kategori         ENUM('starter','profesional','enterprise') NOT NULL UNIQUE,
    harga_per_bulan  DECIMAL(10,2) NOT NULL,
    maks_armada      INT NULL,
    komisi_platform  DECIMAL(5,2) NOT NULL,
    created_at       DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- TABEL VENDORS
-- ============================================================
CREATE TABLE vendors (
    vendor_id           VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    nama_vendor         VARCHAR(150) NOT NULL,
    alamat              TEXT NOT NULL,
    kota                VARCHAR(80),
    kontak_phone        VARCHAR(20),
    kontak_email        VARCHAR(150) UNIQUE,
    password_hash       VARCHAR(255),
    subscription_id     VARCHAR(36) NULL,
    status_langganan    ENUM('active','suspended') DEFAULT 'active',
    tanggal_jatuh_tempo DATE NULL,
    saldo               DECIMAL(14,2) DEFAULT 0,
    biaya_antar         DECIMAL(10,2) DEFAULT 0,
    rating_avg          DECIMAL(3,2) DEFAULT 0.0,
    total_ulasan        INT DEFAULT 0,
    status_aktif        TINYINT(1) DEFAULT 1,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (subscription_id) REFERENCES vendor_subscriptions(subscription_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- TABEL USERS (Penyewa)
-- ============================================================
CREATE TABLE users (
    user_id           VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    nama              VARCHAR(100) NOT NULL,
    nama_lengkap      VARCHAR(150) NULL,
    email             VARCHAR(150) UNIQUE NOT NULL,
    phone             VARCHAR(20),
    password_hash     VARCHAR(255),
    nik               VARCHAR(16) UNIQUE NULL,
    nik_hash          VARCHAR(64) NOT NULL,
    nomor_sim         VARCHAR(30) NOT NULL,
    status_verifikasi ENUM('pending','verified','rejected') DEFAULT 'pending',
    verifikasi_at     DATETIME NULL,
    trust_score       INT DEFAULT 0 CHECK (trust_score >= 0 AND trust_score <= 100),
    level_trust       ENUM('bronze','silver','gold','platinum') DEFAULT 'bronze',
    saldo_ewallet     DECIMAL(12,2) DEFAULT 0,
    foto_profil_url   VARCHAR(500),
    is_active         TINYINT(1) DEFAULT 1,
    created_at        DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_nik_hash (nik_hash),
    INDEX idx_email (email)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL EWALLET (Simulasi Database E-Wallet)
-- ============================================================
CREATE TABLE ewallet_accounts (
    account_id   VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id      VARCHAR(36) NOT NULL,
    metode_bayar ENUM('gopay','ovo','dana','debit','bca_va','mandiri_va') NOT NULL DEFAULT 'gopay',
    saldo        DECIMAL(12,2) DEFAULT 0,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at   DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_user_method (user_id, metode_bayar),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE ewallet_transactions (
    txn_id          VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    account_id      VARCHAR(36) NOT NULL,
    tipe            ENUM('topup','deduct','refund','transfer_out','transfer_in') NOT NULL,
    amount          DECIMAL(12,2) NOT NULL,
    saldo_sebelum   DECIMAL(12,2) NOT NULL,
    saldo_sesudah   DECIMAL(12,2) NOT NULL,
    ref_booking_id  VARCHAR(36) NULL,
    keterangan      VARCHAR(200),
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES ewallet_accounts(account_id),
    INDEX idx_account (account_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL VEHICLES (motor only)
-- ============================================================
CREATE TABLE vehicles (
    vehicle_id      VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    vendor_id       VARCHAR(36) NOT NULL,
    jenis           ENUM('motor') NOT NULL DEFAULT 'motor',
    merek           VARCHAR(60) NOT NULL,
    model           VARCHAR(60) NOT NULL,
    tahun           INT NOT NULL,
    plat_nomor      VARCHAR(15) UNIQUE NOT NULL,
    nomor_stnk      VARCHAR(50) NULL,
    warna           VARCHAR(40),
    status          ENUM('available','rented','maintenance','inactive') DEFAULT 'available',
    tarif_per_jam   DECIMAL(10,2) NOT NULL,
    tarif_deposit   DECIMAL(10,2) NOT NULL,
    kapasitas       INT DEFAULT 2,
    foto_url        VARCHAR(500),
    deskripsi       TEXT,
    fitur           JSON,
    lokasi_lat      DOUBLE DEFAULT -7.7972,
    lokasi_lng      DOUBLE DEFAULT 110.3688,
    iot_device_id   VARCHAR(100),
    rating_avg      DECIMAL(3,2) DEFAULT 4.5,
    total_ulasan    INT DEFAULT 0,
    tarif_per_hari  DECIMAL(10,2) NULL,
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id) ON DELETE CASCADE,
    INDEX idx_vendor (vendor_id),
    INDEX idx_status (status)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL GEOFENCES
-- ============================================================
CREATE TABLE geofences (
    geofence_id   VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    vendor_id     VARCHAR(36),
    nama_lokasi   VARCHAR(150) NOT NULL,
    latitude      DOUBLE NOT NULL,
    longitude     DOUBLE NOT NULL,
    radius_meter  INT NOT NULL DEFAULT 100,
    tipe          ENUM('vendor_garage','station','airport','mall','campus','custom') DEFAULT 'custom',
    pickup_fee    DECIMAL(10,2) DEFAULT 0,
    is_active     TINYINT(1) DEFAULT 1,
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================================
-- TABEL BOOKINGS
-- ============================================================
CREATE TABLE bookings (
    booking_id             VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id                VARCHAR(36) NOT NULL,
    vehicle_id             VARCHAR(36) NOT NULL,
    geofence_id            VARCHAR(36),
    waktu_mulai            DATETIME NOT NULL,
    waktu_selesai          DATETIME NOT NULL,
    waktu_aktual_kembali   DATETIME NULL,
    durasi_jam             INT NOT NULL,
    status_booking         ENUM('pending','confirmed','active','completed','cancelled') DEFAULT 'pending',
    pickup_fee             DECIMAL(10,2) DEFAULT 0,
    unlock_token           VARCHAR(128),
    geofence_validated     TINYINT(1) DEFAULT 0,
    catatan                TEXT,
    delivery_fee           DECIMAL(10,2) DEFAULT 0,
    metode_pengambilan     ENUM('ambil_sendiri','diantar') DEFAULT 'ambil_sendiri',
    created_at             DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at             DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    FOREIGN KEY (geofence_id) REFERENCES geofences(geofence_id) ON DELETE SET NULL,
    INDEX idx_user (user_id),
    INDEX idx_vehicle (vehicle_id),
    INDEX idx_status (status_booking)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL PAYMENTS
-- ============================================================
CREATE TABLE payments (
    payment_id         VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    booking_id         VARCHAR(36) UNIQUE NOT NULL,
    biaya_sewa         DECIMAL(12,2) NOT NULL,
    deposit_virtual    DECIMAL(12,2) NOT NULL,
    pickup_fee         DECIMAL(10,2) DEFAULT 0,
    total_bayar        DECIMAL(12,2) NOT NULL,
    metode_bayar       ENUM('gopay','ovo','dana','debit','bca_va','mandiri_va') NOT NULL,
    status_payment     ENUM('pending','pre_authorized','captured','refunded','failed','partially_refunded') DEFAULT 'pending',
    gateway_ref        VARCHAR(200),
    pre_auth_ref       VARCHAR(200),
    deposit_dilepas_at DATETIME NULL,
    refund_amount      DECIMAL(12,2) DEFAULT 0,
    paid_at            DATETIME NULL,
    created_at         DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at         DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL PENALTIES
-- ============================================================
CREATE TABLE penalties (
    penalty_id            VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    booking_id            VARCHAR(36) NOT NULL,
    durasi_overtime_menit INT NOT NULL,
    tarif_per_jam_denda   DECIMAL(10,2) NOT NULL,
    nominal_denda         DECIMAL(12,2) NOT NULL,
    status_potong         ENUM('pending','deducted','waived') DEFAULT 'pending',
    auto_deduct_at        DATETIME NULL,
    keterangan            TEXT,
    created_at            DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL REVIEWS
-- ============================================================
CREATE TABLE reviews (
    review_id   VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    booking_id  VARCHAR(36) UNIQUE NOT NULL,
    user_id     VARCHAR(36) NOT NULL,
    vehicle_id  VARCHAR(36) NOT NULL,
    rating      TINYINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    komentar    TEXT,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    INDEX idx_vehicle (vehicle_id),
    INDEX idx_user (user_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL IOT_LOGS
-- ============================================================
CREATE TABLE iot_logs (
    log_id         VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    vehicle_id     VARCHAR(36) NOT NULL,
    booking_id     VARCHAR(36),
    lokasi_lat     DOUBLE,
    lokasi_lng     DOUBLE,
    status_mesin   ENUM('on','off','idle') DEFAULT 'off',
    status_kunci   ENUM('locked','unlocked') DEFAULT 'locked',
    kecepatan      DOUBLE DEFAULT 0,
    raw_data       JSON,
    waktu_update   DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE SET NULL,
    INDEX idx_vehicle_time (vehicle_id, waktu_update)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL TRUST_LOGS
-- ============================================================
CREATE TABLE trust_logs (
    log_id       VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id      VARCHAR(36) NOT NULL,
    booking_id   VARCHAR(36),
    parameter    VARCHAR(100) NOT NULL,
    delta_skor   INT NOT NULL,
    skor_sebelum INT NOT NULL,
    skor_sesudah INT NOT NULL,
    keterangan   TEXT,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_user (user_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL UNLOCK_LOGS
-- ============================================================
CREATE TABLE unlock_logs (
    log_id      VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    vehicle_id  VARCHAR(36) NOT NULL,
    user_id     VARCHAR(36),
    booking_id  VARCHAR(36),
    aksi        ENUM('unlock','lock','force_lock','emergency_lock') NOT NULL,
    sumber      ENUM('mobile_app','vendor_dashboard','system_auto','api_gateway') NOT NULL,
    berhasil    TINYINT(1) DEFAULT 1,
    keterangan  TEXT,
    waktu_aksi  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    INDEX idx_vehicle (vehicle_id)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL NOTIFICATIONS
-- ============================================================
CREATE TABLE notifications (
    notif_id   VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id    VARCHAR(36),
    vendor_id  VARCHAR(36),
    tipe       VARCHAR(60) NOT NULL,
    judul      VARCHAR(200) NOT NULL,
    pesan      TEXT,
    data_json  JSON,
    is_read    TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id) ON DELETE CASCADE,
    INDEX idx_user_read (user_id, is_read),
    INDEX idx_vendor_read (vendor_id, is_read)
) ENGINE=InnoDB;

-- ============================================================
-- TABEL REFRESH_TOKENS (rotasi token)
-- ============================================================
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id           VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    user_id      VARCHAR(36),
    vendor_id    VARCHAR(36),
    jti          VARCHAR(36) UNIQUE NOT NULL,
    expires_at   DATETIME NOT NULL,
    revoked      TINYINT(1) DEFAULT 0,
    created_at   DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_jti (jti),
    INDEX idx_user (user_id)
) ENGINE=InnoDB;

-- ============================================================
-- wallet_ledger removed: ewallet_transactions now serves as the per-method audit ledger

-- ============================================================
-- VIEW: booking detail lengkap
-- ============================================================
CREATE OR REPLACE VIEW v_booking_detail AS
SELECT
    b.booking_id, b.vehicle_id, b.status_booking, b.waktu_mulai, b.waktu_selesai,
    b.waktu_aktual_kembali, b.durasi_jam, ROUND(b.durasi_jam / 24) AS durasi_hari,
    b.pickup_fee, b.delivery_fee, b.metode_pengambilan, b.geofence_validated, b.unlock_token, b.catatan,
    u.user_id, u.nama AS nama_penyewa, u.trust_score, u.level_trust, u.phone AS phone_penyewa,
    CONCAT(v.merek,' ',v.model,' ',v.tahun) AS nama_kendaraan,
    v.plat_nomor, v.jenis AS jenis_kendaraan, v.tarif_per_jam, v.tarif_per_hari,
    vn.vendor_id, vn.nama_vendor,
    p.payment_id, p.biaya_sewa, p.total_bayar, p.deposit_virtual, p.status_payment,
    p.metode_bayar, p.refund_amount,
    g.nama_lokasi AS titik_kembali,
    g.latitude AS geo_lat, g.longitude AS geo_lng, g.radius_meter,
    b.created_at
FROM bookings b
JOIN users u ON b.user_id = u.user_id
JOIN vehicles v ON b.vehicle_id = v.vehicle_id
JOIN vendors vn ON v.vendor_id = vn.vendor_id
LEFT JOIN payments p ON b.booking_id = p.booking_id
LEFT JOIN geofences g ON b.geofence_id = g.geofence_id;

-- ============================================================
-- VIEW: vendor dashboard stats (saldo dihitung dinamis)
-- ============================================================
CREATE OR REPLACE VIEW v_vendor_dashboard AS
SELECT
    vn.vendor_id,
    vn.nama_vendor,
    vn.status_langganan,
    vn.tanggal_jatuh_tempo,
    vs.kategori AS kategori_langganan,
    vs.komisi_platform,
    vs.maks_armada,
    vn.saldo AS saldo_akun,
    vn.biaya_antar,
    vn.rating_avg,
    vn.total_ulasan,
    COUNT(DISTINCT v.vehicle_id) AS total_armada,
    COUNT(DISTINCT CASE WHEN v.status = 'available'   THEN v.vehicle_id END) AS unit_tersedia,
    COUNT(DISTINCT CASE WHEN v.status = 'rented'      THEN v.vehicle_id END) AS unit_disewa,
    COUNT(DISTINCT CASE WHEN v.status = 'maintenance' THEN v.vehicle_id END) AS unit_maintenance,
    COALESCE(SUM(CASE WHEN p.status_payment IN ('captured','partially_refunded')
                      THEN p.biaya_sewa + COALESCE(p.pickup_fee, 0) + COALESCE(b.delivery_fee, 0)
                      ELSE 0 END), 0) AS pendapatan_kotor,
    COALESCE(SUM(CASE WHEN p.status_payment IN ('captured','partially_refunded')
                           AND DATE(p.paid_at) = CURDATE()
                      THEN p.biaya_sewa + COALESCE(p.pickup_fee, 0) + COALESCE(b.delivery_fee, 0)
                      ELSE 0 END), 0) AS pendapatan_hari_ini,
    COALESCE(SUM(CASE WHEN p.status_payment IN ('captured','partially_refunded')
                           AND DATE_FORMAT(p.paid_at,'%Y-%m') = DATE_FORMAT(NOW(),'%Y-%m')
                      THEN p.biaya_sewa + COALESCE(p.pickup_fee, 0) + COALESCE(b.delivery_fee, 0)
                      ELSE 0 END), 0) AS pendapatan_bulan_ini,
    COALESCE(SUM(CASE WHEN p.status_payment IN ('captured','partially_refunded')
                      THEN p.biaya_sewa * (1 - COALESCE(vs.komisi_platform, 7) / 100)
                           + COALESCE(p.pickup_fee, 0) + COALESCE(b.delivery_fee, 0)
                      ELSE 0 END), 0) AS pendapatan_total
FROM vendors vn
LEFT JOIN vendor_subscriptions vs ON vn.subscription_id = vs.subscription_id
LEFT JOIN vehicles v ON vn.vendor_id = v.vendor_id
LEFT JOIN bookings b ON v.vehicle_id = b.vehicle_id
LEFT JOIN payments p ON b.booking_id = p.booking_id
GROUP BY vn.vendor_id, vn.nama_vendor, vn.status_langganan, vn.tanggal_jatuh_tempo,
         vn.biaya_antar, vn.rating_avg, vn.total_ulasan,
         vs.kategori, vs.komisi_platform, vs.maks_armada;
