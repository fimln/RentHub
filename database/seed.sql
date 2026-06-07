-- ============================================================
-- RENTHUB - SEED DATA MySQL (Data Demo Yogyakarta)
-- Jalankan SETELAH schema.sql, pada database yang sudah dipilih
-- ============================================================

-- ============================================================
-- DATABASE EKSTERNAL: Dukcapil
-- ============================================================
INSERT INTO dukcapil_datadiri (nik, nama_lengkap, tanggal_lahir) VALUES
('3273010101950001','Budi Santoso','1995-01-01'),
('3273020202960002','Siti Aminah','1996-02-02'),
('3273030303970003','Rudi Hermawan','1997-03-03'),
('3273040404980004','Demo Penyewa','1998-04-04'),
('3273050505990005','Miskin Saldo','1999-05-05'),
('3271061506870006','Ahmad Fauzi','1987-06-15'),
('3578077507920007','Dewi Susanti','1992-07-07'),
('3374088808001008','Hendra Kusuma','2000-08-08'),
('3175099909851009','Ratna Wulandari','1985-09-09'),
('3273101010961010','Joko Pratama','1996-10-10');

-- ============================================================
-- DATABASE EKSTERNAL: Korlantas SIM
-- Semua jenis_sim='C' karena aplikasi hanya untuk motor
-- ============================================================
INSERT INTO korlantas_sim (nomor_sim, nama_lengkap, jenis_sim, tanggal_berlaku, status_aktif) VALUES
('A-9876543210','Budi Santoso','C','2027-12-31',1),
('A-1234567890','Siti Aminah','C','2028-06-30',1),
('A-5555555555','Rudi Hermawan','C','2027-03-15',1),
('A-1111111111','Demo Penyewa','C','2029-01-01',1),
('A-2222222222','Miskin Saldo','C','2026-12-31',1),
('B-3333333333','Ahmad Fauzi','C','2027-09-30',1),
('B-4444444444','Dewi Susanti','C','2028-03-31',1),
('C-5678901234','Hendra Kusuma','C','2027-06-15',1),
('C-9012345678','Ratna Wulandari','C','2026-11-30',1),
('D-1357924680','Joko Pratama','C','2027-08-20',1);

-- ============================================================
-- DATABASE EKSTERNAL: Korlantas Kendaraan
-- ============================================================
INSERT INTO korlantas_kendaraan (nomor_plat, nomor_stnk, tanggal_berlaku_stnk, status_aktif) VALUES
('B 1234 RH', 'STNK-RH-001','2027-01-31',1),
('B 5678 RH', 'STNK-RH-002','2027-01-31',1),
('AB 1111 YK','STNK-RH-003','2027-01-31',1),
('AB 2222 YK','STNK-RH-004','2027-01-31',1),
('AB 9012 YK','STNK-MK-001','2027-01-31',1),
('AB 3456 YK','STNK-MK-002','2027-01-31',1),
('AB 7890 YK','STNK-MK-003','2027-01-31',1),
('AB 1357 YK','STNK-TJ-001','2027-01-31',1),
('AB 2468 YK','STNK-TJ-002','2027-01-31',1);

-- ============================================================
-- VENDOR SUBSCRIPTIONS
-- ============================================================
INSERT INTO vendor_subscriptions (subscription_id, kategori, harga_per_bulan, maks_armada, komisi_platform) VALUES
('sub-001-0000-0000-000000000001','starter',   299000, 5,  7.00),
('sub-002-0000-0000-000000000002','profesional',599000, 20, 6.00),
('sub-003-0000-0000-000000000003','enterprise', 999000, NULL, 5.00);

-- ============================================================
-- VENDORS
-- password_hash adalah bcrypt dari "vendor@123"
-- ============================================================
INSERT INTO vendors (vendor_id, nama_vendor, alamat, kota, kontak_phone, kontak_email, password_hash, subscription_id, status_langganan, tanggal_jatuh_tempo, biaya_antar) VALUES
('ven-001-0000-0000-000000000001','Rental Pak Haji','Jl. Kaliurang No.45, Sleman','Yogyakarta','081234567890','pakhaji@rental.id',   '$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','sub-001-0000-0000-000000000001','active','2027-06-18',25000),
('ven-002-0000-0000-000000000002','MotorKu Yogya',  'Jl. Malioboro No.12, Gedongtengen','Yogyakarta','082345678901','motorku@rental.id',  '$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','sub-001-0000-0000-000000000001','active','2027-06-18',20000),
('ven-003-0000-0000-000000000003','Trans Jogja Rent','Jl. Solo KM5, Maguwoharjo','Yogyakarta','083456789012','transjogja@rental.id','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','sub-002-0000-0000-000000000002','active','2027-06-18',30000);

-- ============================================================
-- USERS
-- demo@renthub.id dan poor@renthub.id: password "demo1234"
-- sisanya: password "user@123"
-- ============================================================
INSERT INTO users (user_id, nama, nama_lengkap, email, phone, password_hash, nik, nik_hash, nomor_sim, status_verifikasi, verifikasi_at, trust_score, level_trust, saldo_ewallet) VALUES
('usr-001-0000-0000-000000000001','Budi Santoso', 'Budi Santoso', 'budi@example.com','081111111111','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273010101950001',SHA2('3273010101950001',256),'A-9876543210','verified',NOW() - INTERVAL 30 DAY,82,'silver',  500000),
('usr-002-0000-0000-000000000002','Siti Aminah',  'Siti Aminah',  'siti@example.com','082222222222','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273020202960002',SHA2('3273020202960002',256),'A-1234567890','verified',NOW() - INTERVAL 60 DAY,95,'platinum',1200000),
('usr-003-0000-0000-000000000003','Rudi Hermawan','Rudi Hermawan','rudi@example.com','083333333333','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273030303970003',SHA2('3273030303970003',256),'A-5555555555','verified',NOW() - INTERVAL 10 DAY,45,'bronze',  200000),
('usr-004-0000-0000-000000000004','Demo Penyewa', 'Demo Penyewa', 'demo@renthub.id', '089900000001','$2b$10$Tn9kp27FXQwe0xuj2BzZE./9fOyAKXAiUn4WQaTax3qs4VqP05sSu','3273040404980004',SHA2('3273040404980004',256),'A-1111111111','verified',NOW() - INTERVAL 1 DAY, 70,'silver',  1000000),
('usr-005-0000-0000-000000000005','Miskin Saldo', 'Miskin Saldo', 'poor@renthub.id', '089900000002','$2b$10$Tn9kp27FXQwe0xuj2BzZE./9fOyAKXAiUn4WQaTax3qs4VqP05sSu','3273050505990005',SHA2('3273050505990005',256),'A-2222222222','verified',NOW() - INTERVAL 1 DAY, 50,'silver',  50000);

-- ============================================================
-- EWALLET ACCOUNTS & TRANSACTIONS
-- ============================================================
INSERT INTO ewallet_accounts (account_id, user_id, metode_bayar, saldo) VALUES
-- usr-001 (total ~500rb)
('ewa-001-0000-0000-000000000001','usr-001-0000-0000-000000000001','gopay',200000),
('ewa-001-0000-0000-000000000002','usr-001-0000-0000-000000000001','ovo',150000),
('ewa-001-0000-0000-000000000003','usr-001-0000-0000-000000000001','dana',100000),
('ewa-001-0000-0000-000000000004','usr-001-0000-0000-000000000001','debit',50000),
-- usr-002 (total ~1.2jt)
('ewa-002-0000-0000-000000000001','usr-002-0000-0000-000000000002','gopay',500000),
('ewa-002-0000-0000-000000000002','usr-002-0000-0000-000000000002','ovo',300000),
('ewa-002-0000-0000-000000000003','usr-002-0000-0000-000000000002','dana',250000),
('ewa-002-0000-0000-000000000004','usr-002-0000-0000-000000000002','bca_va',150000),
-- usr-003 (total ~200rb)
('ewa-003-0000-0000-000000000001','usr-003-0000-0000-000000000003','gopay',100000),
('ewa-003-0000-0000-000000000002','usr-003-0000-0000-000000000003','ovo',50000),
('ewa-003-0000-0000-000000000003','usr-003-0000-0000-000000000003','dana',50000),
-- usr-004 (demo: total 1jt)
('ewa-004-0000-0000-000000000001','usr-004-0000-0000-000000000004','gopay',400000),
('ewa-004-0000-0000-000000000002','usr-004-0000-0000-000000000004','ovo',250000),
('ewa-004-0000-0000-000000000003','usr-004-0000-0000-000000000004','dana',200000),
('ewa-004-0000-0000-000000000004','usr-004-0000-0000-000000000004','debit',150000),
-- usr-005 (total ~50rb)
('ewa-005-0000-0000-000000000001','usr-005-0000-0000-000000000005','gopay',30000),
('ewa-005-0000-0000-000000000002','usr-005-0000-0000-000000000005','dana',20000);

INSERT INTO ewallet_transactions (account_id, tipe, amount, saldo_sebelum, saldo_sesudah, keterangan) VALUES
-- usr-001 tops
('ewa-001-0000-0000-000000000001','topup',200000,0,200000,'Top up GOPAY'),
('ewa-001-0000-0000-000000000002','topup',150000,0,150000,'Top up OVO'),
('ewa-001-0000-0000-000000000003','topup',100000,0,100000,'Top up DANA'),
('ewa-001-0000-0000-000000000004','topup',50000, 0,50000, 'Top up Kartu Debit'),
-- usr-002 tops
('ewa-002-0000-0000-000000000001','topup',500000,0,500000,'Top up GOPAY'),
('ewa-002-0000-0000-000000000002','topup',300000,0,300000,'Top up OVO'),
('ewa-002-0000-0000-000000000003','topup',250000,0,250000,'Top up DANA'),
('ewa-002-0000-0000-000000000004','topup',150000,0,150000,'Top up BCA VA'),
-- usr-003 tops
('ewa-003-0000-0000-000000000001','topup',100000,0,100000,'Top up GOPAY'),
('ewa-003-0000-0000-000000000002','topup',50000, 0,50000, 'Top up OVO'),
('ewa-003-0000-0000-000000000003','topup',50000, 0,50000, 'Top up DANA'),
-- usr-004 demo tops
('ewa-004-0000-0000-000000000001','topup',400000,0,400000,'Top up GOPAY'),
('ewa-004-0000-0000-000000000002','topup',250000,0,250000,'Top up OVO'),
('ewa-004-0000-0000-000000000003','topup',200000,0,200000,'Top up DANA'),
('ewa-004-0000-0000-000000000004','topup',150000,0,150000,'Top up Kartu Debit'),
-- usr-005 tops
('ewa-005-0000-0000-000000000001','topup',30000, 0,30000, 'Top up GOPAY'),
('ewa-005-0000-0000-000000000002','topup',20000, 0,20000, 'Top up DANA');

-- ============================================================
-- GEOFENCES
-- ============================================================
INSERT INTO geofences (geofence_id, vendor_id, nama_lokasi, latitude, longitude, radius_meter, tipe, pickup_fee) VALUES
('geo-001-0000-0000-000000000001','ven-001-0000-0000-000000000001','Garasi Rental Pak Haji',  -7.7600,110.3800,100,'vendor_garage',0),
('geo-002-0000-0000-000000000002','ven-002-0000-0000-000000000002','Garasi MotorKu Yogya',    -7.7950,110.3700,100,'vendor_garage',0),
('geo-003-0000-0000-000000000003',NULL,                            'Stasiun Tugu Yogyakarta', -7.7893,110.3641,150,'station',50000),
('geo-004-0000-0000-000000000004',NULL,                            'Bandara YIA Kulon Progo', -7.9025,110.0570,200,'airport',75000),
('geo-005-0000-0000-000000000005',NULL,                            'Malioboro Mall',          -7.7931,110.3659,100,'mall',35000),
('geo-006-0000-0000-000000000006',NULL,                            'UGM Bulaksumur',          -7.7714,110.3783,150,'campus',40000);

-- ============================================================
-- VEHICLES - Rental Pak Haji
-- ============================================================
INSERT INTO vehicles (vehicle_id, vendor_id, jenis, merek, model, tahun, plat_nomor, nomor_stnk, warna, status, tarif_per_jam, tarif_deposit, kapasitas, deskripsi, fitur, lokasi_lat, lokasi_lng, rating_avg, total_ulasan) VALUES
('veh-001','ven-001-0000-0000-000000000001','motor','Honda','Beat',     2023,'B 1234 RH', 'STNK-RH-001','Hitam Merah','rented',   45000,150000,2,'Motor matic Honda Beat 2023 kondisi prima',          '["GPS Tracking","Smart Lock","Asuransi","Helm Inkl."]',             -7.7848,110.3790,4.8,127),
('veh-002','ven-001-0000-0000-000000000001','motor','Honda','Vario 150',2022,'B 5678 RH', 'STNK-RH-002','Putih',      'available',50000,150000,2,'Honda Vario 150 nyaman untuk touring kota',          '["GPS Tracking","Smart Lock","Asuransi","Helm Inkl."]',             -7.7610,110.3810,4.6,89),
('veh-003','ven-001-0000-0000-000000000001','motor','Yamaha','NMAX',    2022,'AB 1111 YK','STNK-RH-003','Biru',       'available',65000,200000,2,'Yamaha NMAX 155cc motor premium touring',            '["GPS Tracking","Smart Lock","Asuransi","Helm Inkl.","USB Charger"]',-7.7605,110.3805,4.9,203),
('veh-004','ven-001-0000-0000-000000000001','motor','Honda','PCX 160',  2023,'AB 2222 YK','STNK-RH-004','Abu-abu',    'maintenance',60000,180000,2,'Honda PCX 160 dalam proses servis rutin',           '["GPS Tracking","Smart Lock","Asuransi"]',                          -7.7615,110.3815,4.7,56);

-- ============================================================
-- VEHICLES - MotorKu Yogya (motor)
-- ============================================================
INSERT INTO vehicles (vehicle_id, vendor_id, jenis, merek, model, tahun, plat_nomor, nomor_stnk, warna, status, tarif_per_jam, tarif_deposit, kapasitas, deskripsi, fitur, lokasi_lat, lokasi_lng, rating_avg, total_ulasan) VALUES
('veh-005','ven-002-0000-0000-000000000002','motor','Yamaha','Mio M3',  2022,'AB 9012 YK','STNK-MK-001','Biru',  'available',40000,100000,2,'Yamaha Mio M3 matic ringan hemat BBM',         '["GPS Tracking","Smart Lock","Asuransi","Helm Inkl."]',-7.7950,110.3700,4.2,67),
('veh-006','ven-002-0000-0000-000000000002','motor','Honda','Scoopy',   2023,'AB 3456 YK','STNK-MK-002','Putih', 'available',45000,100000,2,'Honda Scoopy 2023 stylish dan nyaman',          '["GPS Tracking","Smart Lock","Asuransi","Helm Inkl."]',-7.7960,110.3710,4.4,54),
('veh-007','ven-002-0000-0000-000000000002','motor','Honda','Genio',    2022,'AB 7890 YK','STNK-MK-003','Merah', 'available',40000,100000,2,'Honda Genio lincah untuk dalam kota',           '["GPS Tracking","Smart Lock","Asuransi","Helm Inkl."]',-7.7940,110.3690,4.1,38);

-- ============================================================
-- VEHICLES - Trans Jogja Rent (motor)
-- ============================================================
INSERT INTO vehicles (vehicle_id, vendor_id, jenis, merek, model, tahun, plat_nomor, nomor_stnk, warna, status, tarif_per_jam, tarif_deposit, kapasitas, deskripsi, fitur, lokasi_lat, lokasi_lng, rating_avg, total_ulasan) VALUES
('veh-008','ven-003-0000-0000-000000000003','motor','Yamaha','Aerox 155',2023,'AB 1357 YK','STNK-TJ-001','Hitam',  'available',55000,150000,2,'Yamaha Aerox 155 sporty bertenaga',       '["GPS Tracking","Smart Lock","Asuransi","Helm Inkl.","USB Charger"]',-7.8000,110.3750,4.7,31),
('veh-009','ven-003-0000-0000-000000000003','motor','Honda','ADV 150',   2022,'AB 2468 YK','STNK-TJ-002','Abu-abu','available',60000,150000,2,'Honda ADV 150 adventure motor tangguh',   '["GPS Tracking","Smart Lock","Asuransi","Helm Inkl.","USB Charger"]',-7.8010,110.3760,4.6,22);

-- ============================================================
-- SET TARIF PER HARI untuk setiap kendaraan
-- ============================================================
UPDATE vehicles SET tarif_per_hari = 80000  WHERE vehicle_id = 'veh-001'; -- Honda Beat
UPDATE vehicles SET tarif_per_hari = 90000  WHERE vehicle_id = 'veh-002'; -- Honda Vario 150
UPDATE vehicles SET tarif_per_hari = 120000 WHERE vehicle_id = 'veh-003'; -- Yamaha NMAX
UPDATE vehicles SET tarif_per_hari = 110000 WHERE vehicle_id = 'veh-004'; -- Honda PCX 160
UPDATE vehicles SET tarif_per_hari = 75000  WHERE vehicle_id = 'veh-005'; -- Yamaha Mio M3
UPDATE vehicles SET tarif_per_hari = 80000  WHERE vehicle_id = 'veh-006'; -- Honda Scoopy
UPDATE vehicles SET tarif_per_hari = 75000  WHERE vehicle_id = 'veh-007'; -- Honda Genio
UPDATE vehicles SET tarif_per_hari = 100000 WHERE vehicle_id = 'veh-008'; -- Yamaha Aerox 155
UPDATE vehicles SET tarif_per_hari = 110000 WHERE vehicle_id = 'veh-009'; -- Honda ADV 150

-- ============================================================
-- IOT DEVICE IDS
-- ============================================================
UPDATE vehicles SET iot_device_id='IOT-RH-001' WHERE vehicle_id='veh-001';
UPDATE vehicles SET iot_device_id='IOT-RH-002' WHERE vehicle_id='veh-002';
UPDATE vehicles SET iot_device_id='IOT-RH-003' WHERE vehicle_id='veh-003';

-- ============================================================
-- TRUST LOGS untuk Budi
-- ============================================================
INSERT INTO trust_logs (user_id, parameter, delta_skor, skor_sebelum, skor_sesudah, keterangan, created_at) VALUES
('usr-001-0000-0000-000000000001','verifikasi_identitas',      20, 0,20,'NIK dan SIM C terverifikasi',                 NOW() - INTERVAL 30 DAY),
('usr-001-0000-0000-000000000001','sewa_selesai_tepat_waktu',  10,20,30,'Sewa Honda Beat selesai tepat waktu',          NOW() - INTERVAL 25 DAY),
('usr-001-0000-0000-000000000001','sewa_selesai_tepat_waktu',  10,30,40,'Sewa Yamaha NMAX selesai tepat waktu',         NOW() - INTERVAL 20 DAY),
('usr-001-0000-0000-000000000001','keterlambatan_berat',      -20,40,20,'Overtime 2 jam Honda Vario',                   NOW() - INTERVAL 15 DAY),
('usr-001-0000-0000-000000000001','riwayat_3x_bersih',         30,20,50,'3 transaksi berturut tanpa pelanggaran',       NOW() - INTERVAL 10 DAY),
('usr-001-0000-0000-000000000001','saldo_tidak_cukup',         -5,50,45,'Gagal bayar saat checkout',                    NOW() - INTERVAL 7 DAY),
('usr-001-0000-0000-000000000001','referral_pengguna',         37,45,82,'Referral 3 pengguna baru',                     NOW() - INTERVAL 3 DAY);

-- ============================================================
-- NOTIFIKASI DEMO
-- ============================================================
INSERT INTO notifications (user_id, tipe, judul, pesan, is_read, created_at) VALUES
('usr-001-0000-0000-000000000001','payment_success',  'Pembayaran Berhasil!',    'Honda Beat 2023 siap digunakan. Smart unlock aktif.',           1,NOW() - INTERVAL 2 HOUR),
('usr-001-0000-0000-000000000001','trust_score_up',   'Trust Score Naik ke 82!', 'Selamat! +10 poin karena mengembalikan tepat waktu.',           1,NOW() - INTERVAL 1 DAY),
('usr-001-0000-0000-000000000001','deposit_refund',   'Deposit Dikembalikan',    'Rp150.000 telah dikembalikan ke e-wallet Anda.',                1,NOW() - INTERVAL 1 DAY);

INSERT INTO notifications (vendor_id, tipe, judul, pesan, is_read, created_at) VALUES
('ven-001-0000-0000-000000000001','vehicle_rented',    'Kendaraan B 1234 RH Disewa',   'Penyewa: Demo Penyewa. Trust Score: 70. Selesai besok.',0,NOW() - INTERVAL 2 HOUR),
('ven-001-0000-0000-000000000001','overtime_deducted', 'Denda Overtime Dipotong',       'Rp50.000 dari deposit AB 1111 YK. Overtime 1 jam.',    0,NOW() - INTERVAL 3 HOUR);

-- ============================================================
-- ACTIVE BOOKING (Demo IoT - Honda Beat B 1234 RH sedang disewa)
-- ============================================================
INSERT INTO bookings (booking_id, user_id, vehicle_id, geofence_id, waktu_mulai, waktu_selesai, durasi_jam, status_booking, metode_pengambilan, unlock_token) VALUES
('bkn-001-0000-0000-000000000001','usr-004-0000-0000-000000000004','veh-001','geo-001-0000-0000-000000000001',NOW() - INTERVAL 2 HOUR,NOW() + INTERVAL 22 HOUR,24,'active','ambil_sendiri','demo-unlock-bkn001-token-000001');

INSERT INTO payments (payment_id, booking_id, biaya_sewa, deposit_virtual, total_bayar, metode_bayar, status_payment, paid_at) VALUES
('pay-001-0000-0000-000000000001','bkn-001-0000-0000-000000000001',80000,150000,230000,'gopay','pre_authorized',NOW() - INTERVAL 2 HOUR);

-- Kurangi saldo gopay usr-004 untuk booking aktif (total_bayar=230000)
UPDATE ewallet_accounts SET saldo = 170000 WHERE account_id = 'ewa-004-0000-0000-000000000001';
INSERT INTO ewallet_transactions (account_id, tipe, amount, saldo_sebelum, saldo_sesudah, ref_booking_id, keterangan) VALUES
('ewa-004-0000-0000-000000000001','deduct',230000,400000,170000,'bkn-001-0000-0000-000000000001','Pembayaran booking bkn-001');

-- ============================================================
-- IOT LOGS (Honda Beat B 1234 RH - sedang dikendarai Demo Penyewa)
-- ============================================================
INSERT INTO iot_logs (vehicle_id, booking_id, lokasi_lat, lokasi_lng, status_mesin, status_kunci, kecepatan, raw_data, waktu_update) VALUES
('veh-001','bkn-001-0000-0000-000000000001',-7.7820,110.3775,'on','unlocked',25.5,'{"signal":"GPS","battery":87,"temp":28}',NOW() - INTERVAL 5 MINUTE),
('veh-001','bkn-001-0000-0000-000000000001',-7.7835,110.3782,'on','unlocked',18.2,'{"signal":"GPS","battery":86,"temp":28}',NOW() - INTERVAL 3 MINUTE),
('veh-001','bkn-001-0000-0000-000000000001',-7.7848,110.3790,'on','unlocked', 0.0,'{"signal":"GPS","battery":86,"temp":29}',NOW() - INTERVAL 1 MINUTE);

-- ============================================================
-- ============================================================
-- BI DEMO DATA (Historis 6 bulan untuk analytics & dashboard)
-- ============================================================
-- ============================================================

-- ============================================================
-- DUKCAPIL: Data diri 25 user tambahan
-- ============================================================
INSERT INTO dukcapil_datadiri (nik, nama_lengkap, tanggal_lahir) VALUES
('3273120395000000','Andi Wijaya','1995-03-12'),
('3273220793000000','Bayu Aditya','1993-07-22'),
('3273051197000000','Citra Lestari','1997-11-05'),
('3273180490000000','Dimas Pratama','1990-04-18'),
('3273300994000000','Eko Saputra','1994-09-30'),
('3273140296000000','Fitri Handayani','1996-02-14'),
('3273080891000000','Galih Permana','1991-08-08'),
('3273201289000000','Hesti Maharani','1989-12-20'),
('3273250695000000','Indra Gunawan','1995-06-25'),
('3273150398000000','Jihan Safitri','1998-03-15'),
('3273101092000000','Kurnia Dewi','1992-10-10'),
('3273190588000000','Lukman Hakim','1988-05-19'),
('3273281194000000','Maya Anggraini','1994-11-28'),
('3273040796000000','Nanda Pratiwi','1996-07-04'),
('3273220190000000','Oki Setiawan','1990-01-22'),
('3273110493000000','Putri Rahayu','1993-04-11'),
('3273170995000000','Qori Andini','1995-09-17'),
('3273031291000000','Reza Maulana','1991-12-03'),
('3273140689000000','Sri Wahyuni','1989-06-14'),
('3273080294000000','Tedi Sutrisno','1994-02-08'),
('3273260892000000','Umar Halim','1992-08-26'),
('3273310597000000','Vina Marlina','1997-05-31'),
('3273091088000000','Wahyu Hidayat','1988-10-09'),
('3273270393000000','Xenia Putri','1993-03-27'),
('3273120790000000','Yusuf Ramadhan','1990-07-12');

-- ============================================================
-- KORLANTAS SIM: SIM C untuk 25 user tambahan
-- ============================================================
INSERT INTO korlantas_sim (nomor_sim, nama_lengkap, jenis_sim, tanggal_berlaku, status_aktif) VALUES
('SIM-006-006666','Andi Wijaya','C','2027-04-30',1),
('SIM-007-007777','Bayu Aditya','C','2028-08-15',1),
('SIM-008-008888','Citra Lestari','C','2027-11-30',1),
('SIM-009-009999','Dimas Pratama','C','2028-02-28',1),
('SIM-010-011110','Eko Saputra','C','2027-07-15',1),
('SIM-011-012221','Fitri Handayani','C','2028-05-31',1),
('SIM-012-013332','Galih Permana','C','2027-10-31',1),
('SIM-013-014443','Hesti Maharani','C','2028-12-15',1),
('SIM-014-015554','Indra Gunawan','C','2027-06-30',1),
('SIM-015-016665','Jihan Safitri','C','2028-09-30',1),
('SIM-016-017776','Kurnia Dewi','C','2027-03-15',1),
('SIM-017-018887','Lukman Hakim','C','2028-01-31',1),
('SIM-018-019998','Maya Anggraini','C','2028-07-31',1),
('SIM-019-021109','Nanda Pratiwi','C','2027-12-15',1),
('SIM-020-022220','Oki Setiawan','C','2028-04-30',1),
('SIM-021-023331','Putri Rahayu','C','2028-10-15',1),
('SIM-022-024442','Qori Andini','C','2027-09-30',1),
('SIM-023-025553','Reza Maulana','C','2028-11-30',1),
('SIM-024-026664','Sri Wahyuni','C','2028-06-15',1),
('SIM-025-027775','Tedi Sutrisno','C','2027-05-31',1),
('SIM-026-028886','Umar Halim','C','2028-03-31',1),
('SIM-027-029997','Vina Marlina','C','2028-08-31',1),
('SIM-028-031108','Wahyu Hidayat','C','2027-08-15',1),
('SIM-029-032219','Xenia Putri','C','2028-12-31',1),
('SIM-030-033330','Yusuf Ramadhan','C','2029-02-28',1);

-- ============================================================
-- USERS: 25 user tambahan (usr-006 s/d usr-030)
-- Distribusi: 5 bronze, 10 silver, 7 gold, 3 platinum
-- ============================================================
INSERT INTO users (user_id, nama, nama_lengkap, email, phone, password_hash, nik, nik_hash, nomor_sim, status_verifikasi, verifikasi_at, trust_score, level_trust, saldo_ewallet) VALUES
('usr-006-0000-0000-000000000006','Andi Wijaya','Andi Wijaya','andi6@example.com','081005925924','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273120395000000',SHA2('3273120395000000',256),'SIM-006-006666','verified',NOW() - INTERVAL 180 DAY,15,'bronze',75000),
('usr-007-0000-0000-000000000007','Bayu Aditya','Bayu Aditya','bayu7@example.com','081006913578','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273220793000000',SHA2('3273220793000000',256),'SIM-007-007777','verified',NOW() - INTERVAL 175 DAY,22,'bronze',120000),
('usr-008-0000-0000-000000000008','Citra Lestari','Citra Lestari','citra8@example.com','081007901232','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273051197000000',SHA2('3273051197000000',256),'SIM-008-008888','verified',NOW() - INTERVAL 170 DAY,30,'bronze',95000),
('usr-009-0000-0000-000000000009','Dimas Pratama','Dimas Pratama','dimas9@example.com','081008888886','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273180490000000',SHA2('3273180490000000',256),'SIM-009-009999','verified',NOW() - INTERVAL 165 DAY,35,'bronze',180000),
('usr-010-0000-0000-000000000010','Eko Saputra','Eko Saputra','eko10@example.com','081009876540','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273300994000000',SHA2('3273300994000000',256),'SIM-010-011110','verified',NOW() - INTERVAL 160 DAY,38,'bronze',60000),
('usr-011-0000-0000-000000000011','Fitri Handayani','Fitri Handayani','fitri11@example.com','081010864194','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273140296000000',SHA2('3273140296000000',256),'SIM-011-012221','verified',NOW() - INTERVAL 150 DAY,42,'silver',250000),
('usr-012-0000-0000-000000000012','Galih Permana','Galih Permana','galih12@example.com','081011851848','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273080891000000',SHA2('3273080891000000',256),'SIM-012-013332','verified',NOW() - INTERVAL 145 DAY,48,'silver',320000),
('usr-013-0000-0000-000000000013','Hesti Maharani','Hesti Maharani','hesti13@example.com','081012839502','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273201289000000',SHA2('3273201289000000',256),'SIM-013-014443','verified',NOW() - INTERVAL 140 DAY,52,'silver',410000),
('usr-014-0000-0000-000000000014','Indra Gunawan','Indra Gunawan','indra14@example.com','081013827156','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273250695000000',SHA2('3273250695000000',256),'SIM-014-015554','verified',NOW() - INTERVAL 135 DAY,55,'silver',280000),
('usr-015-0000-0000-000000000015','Jihan Safitri','Jihan Safitri','jihan15@example.com','081014814810','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273150398000000',SHA2('3273150398000000',256),'SIM-015-016665','verified',NOW() - INTERVAL 130 DAY,58,'silver',560000),
('usr-016-0000-0000-000000000016','Kurnia Dewi','Kurnia Dewi','kurnia16@example.com','081015802464','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273101092000000',SHA2('3273101092000000',256),'SIM-016-017776','verified',NOW() - INTERVAL 125 DAY,60,'silver',470000),
('usr-017-0000-0000-000000000017','Lukman Hakim','Lukman Hakim','lukman17@example.com','081016790118','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273190588000000',SHA2('3273190588000000',256),'SIM-017-018887','verified',NOW() - INTERVAL 120 DAY,62,'silver',330000),
('usr-018-0000-0000-000000000018','Maya Anggraini','Maya Anggraini','maya18@example.com','081017777772','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273281194000000',SHA2('3273281194000000',256),'SIM-018-019998','verified',NOW() - INTERVAL 115 DAY,65,'silver',620000),
('usr-019-0000-0000-000000000019','Nanda Pratiwi','Nanda Pratiwi','nanda19@example.com','081018765426','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273040796000000',SHA2('3273040796000000',256),'SIM-019-021109','verified',NOW() - INTERVAL 110 DAY,67,'silver',510000),
('usr-020-0000-0000-000000000020','Oki Setiawan','Oki Setiawan','oki20@example.com','081019753080','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273220190000000',SHA2('3273220190000000',256),'SIM-020-022220','verified',NOW() - INTERVAL 105 DAY,68,'silver',390000),
('usr-021-0000-0000-000000000021','Putri Rahayu','Putri Rahayu','putri21@example.com','081020740734','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273110493000000',SHA2('3273110493000000',256),'SIM-021-023331','verified',NOW() - INTERVAL 100 DAY,70,'gold',780000),
('usr-022-0000-0000-000000000022','Qori Andini','Qori Andini','qori22@example.com','081021728388','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273170995000000',SHA2('3273170995000000',256),'SIM-022-024442','verified',NOW() - INTERVAL 95 DAY,73,'gold',650000),
('usr-023-0000-0000-000000000023','Reza Maulana','Reza Maulana','reza23@example.com','081022716042','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273031291000000',SHA2('3273031291000000',256),'SIM-023-025553','verified',NOW() - INTERVAL 90 DAY,75,'gold',920000),
('usr-024-0000-0000-000000000024','Sri Wahyuni','Sri Wahyuni','sri24@example.com','081023703696','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273140689000000',SHA2('3273140689000000',256),'SIM-024-026664','verified',NOW() - INTERVAL 85 DAY,78,'gold',830000),
('usr-025-0000-0000-000000000025','Tedi Sutrisno','Tedi Sutrisno','tedi25@example.com','081024691350','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273080294000000',SHA2('3273080294000000',256),'SIM-025-027775','verified',NOW() - INTERVAL 80 DAY,80,'gold',1100000),
('usr-026-0000-0000-000000000026','Umar Halim','Umar Halim','umar26@example.com','081025679004','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273260892000000',SHA2('3273260892000000',256),'SIM-026-028886','verified',NOW() - INTERVAL 70 DAY,82,'gold',740000),
('usr-027-0000-0000-000000000027','Vina Marlina','Vina Marlina','vina27@example.com','081026666658','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273310597000000',SHA2('3273310597000000',256),'SIM-027-029997','verified',NOW() - INTERVAL 60 DAY,84,'gold',960000),
('usr-028-0000-0000-000000000028','Wahyu Hidayat','Wahyu Hidayat','wahyu28@example.com','081027654312','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273091088000000',SHA2('3273091088000000',256),'SIM-028-031108','verified',NOW() - INTERVAL 50 DAY,87,'platinum',1500000),
('usr-029-0000-0000-000000000029','Xenia Putri','Xenia Putri','xenia29@example.com','081028641966','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273270393000000',SHA2('3273270393000000',256),'SIM-029-032219','verified',NOW() - INTERVAL 40 DAY,92,'platinum',1850000),
('usr-030-0000-0000-000000000030','Yusuf Ramadhan','Yusuf Ramadhan','yusuf30@example.com','081029629620','$2b$10$rOzJqQxVyH1mV7K8nP3e8OtXx1Y2Z3A4B5C6D7E8F9G0H1I2J3K4L','3273120790000000',SHA2('3273120790000000',256),'SIM-030-033330','verified',NOW() - INTERVAL 35 DAY,98,'platinum',2200000);

-- ============================================================
-- EWALLET ACCOUNTS untuk 25 user tambahan
-- ============================================================
INSERT INTO ewallet_accounts (account_id, user_id, metode_bayar, saldo) VALUES
-- usr-006
('ewa-006-0000-0000-000000000001','usr-006-0000-0000-000000000006','gopay',50000),
('ewa-006-0000-0000-000000000002','usr-006-0000-0000-000000000006','dana',25000),
-- usr-007
('ewa-007-0000-0000-000000000001','usr-007-0000-0000-000000000007','gopay',70000),
('ewa-007-0000-0000-000000000002','usr-007-0000-0000-000000000007','ovo',50000),
-- usr-008
('ewa-008-0000-0000-000000000001','usr-008-0000-0000-000000000008','gopay',50000),
('ewa-008-0000-0000-000000000002','usr-008-0000-0000-000000000008','ovo',45000),
-- usr-009..030 masing-masing 1 gopay + 1 dana
('ewa-009-0000-0000-000000000001','usr-009-0000-0000-000000000009','gopay',100000),
('ewa-009-0000-0000-000000000002','usr-009-0000-0000-000000000009','dana',80000),
('ewa-010-0000-0000-000000000001','usr-010-0000-0000-000000000010','gopay',35000),
('ewa-010-0000-0000-000000000002','usr-010-0000-0000-000000000010','dana',25000),
('ewa-011-0000-0000-000000000001','usr-011-0000-0000-000000000011','gopay',150000),
('ewa-011-0000-0000-000000000002','usr-011-0000-0000-000000000011','debit',100000),
('ewa-012-0000-0000-000000000001','usr-012-0000-0000-000000000012','gopay',180000),
('ewa-012-0000-0000-000000000002','usr-012-0000-0000-000000000012','dana',140000),
('ewa-013-0000-0000-000000000001','usr-013-0000-0000-000000000013','gopay',210000),
('ewa-013-0000-0000-000000000002','usr-013-0000-0000-000000000013','ovo',200000),
('ewa-014-0000-0000-000000000001','usr-014-0000-0000-000000000014','gopay',150000),
('ewa-014-0000-0000-000000000002','usr-014-0000-0000-000000000014','dana',130000),
('ewa-015-0000-0000-000000000001','usr-015-0000-0000-000000000015','gopay',300000),
('ewa-015-0000-0000-000000000002','usr-015-0000-0000-000000000015','debit',260000),
('ewa-016-0000-0000-000000000001','usr-016-0000-0000-000000000016','gopay',250000),
('ewa-016-0000-0000-000000000002','usr-016-0000-0000-000000000016','dana',220000),
('ewa-017-0000-0000-000000000001','usr-017-0000-0000-000000000017','gopay',180000),
('ewa-017-0000-0000-000000000002','usr-017-0000-0000-000000000017','ovo',150000),
('ewa-018-0000-0000-000000000001','usr-018-0000-0000-000000000018','gopay',350000),
('ewa-018-0000-0000-000000000002','usr-018-0000-0000-000000000018','bca_va',270000),
('ewa-019-0000-0000-000000000001','usr-019-0000-0000-000000000019','gopay',260000),
('ewa-019-0000-0000-000000000002','usr-019-0000-0000-000000000019','debit',250000),
('ewa-020-0000-0000-000000000001','usr-020-0000-0000-000000000020','gopay',200000),
('ewa-020-0000-0000-000000000002','usr-020-0000-0000-000000000020','dana',190000),
('ewa-021-0000-0000-000000000001','usr-021-0000-0000-000000000021','gopay',400000),
('ewa-021-0000-0000-000000000002','usr-021-0000-0000-000000000021','bca_va',380000),
('ewa-022-0000-0000-000000000001','usr-022-0000-0000-000000000022','gopay',350000),
('ewa-022-0000-0000-000000000002','usr-022-0000-0000-000000000022','dana',300000),
('ewa-023-0000-0000-000000000001','usr-023-0000-0000-000000000023','gopay',500000),
('ewa-023-0000-0000-000000000002','usr-023-0000-0000-000000000023','bca_va',420000),
('ewa-024-0000-0000-000000000001','usr-024-0000-0000-000000000024','gopay',450000),
('ewa-024-0000-0000-000000000002','usr-024-0000-0000-000000000024','dana',380000),
('ewa-025-0000-0000-000000000001','usr-025-0000-0000-000000000025','gopay',600000),
('ewa-025-0000-0000-000000000002','usr-025-0000-0000-000000000025','bca_va',500000),
('ewa-026-0000-0000-000000000001','usr-026-0000-0000-000000000026','gopay',400000),
('ewa-026-0000-0000-000000000002','usr-026-0000-0000-000000000026','dana',340000),
('ewa-027-0000-0000-000000000001','usr-027-0000-0000-000000000027','gopay',500000),
('ewa-027-0000-0000-000000000002','usr-027-0000-0000-000000000027','bca_va',460000),
('ewa-028-0000-0000-000000000001','usr-028-0000-0000-000000000028','gopay',800000),
('ewa-028-0000-0000-000000000002','usr-028-0000-0000-000000000028','bca_va',700000),
('ewa-029-0000-0000-000000000001','usr-029-0000-0000-000000000029','gopay',1000000),
('ewa-029-0000-0000-000000000002','usr-029-0000-0000-000000000029','bca_va',850000),
('ewa-030-0000-0000-000000000001','usr-030-0000-0000-000000000030','gopay',1200000),
('ewa-030-0000-0000-000000000002','usr-030-0000-0000-000000000030','bca_va',1000000);

-- ============================================================
-- KORLANTAS KENDARAAN: 6 plat baru untuk veh-010 s/d veh-015
-- ============================================================
INSERT INTO korlantas_kendaraan (nomor_plat, nomor_stnk, tanggal_berlaku_stnk, status_aktif) VALUES
('AB 1010 RH', 'STNK-RH-005','2028-03-31',1),
('AB 1111 RH', 'STNK-RH-006','2028-04-30',1),
('AB 1212 MK', 'STNK-MK-004','2028-05-31',1),
('AB 1313 MK', 'STNK-MK-005','2028-06-30',1),
('AB 1414 TJ', 'STNK-TJ-003','2028-07-31',1),
('AB 1515 TJ', 'STNK-TJ-004','2028-08-31',1);

-- ============================================================
-- VEHICLES: 6 kendaraan tambahan (veh-010 s/d veh-015)
-- veh-010,011 -> ven-001 | veh-012,013 -> ven-002 | veh-014,015 -> ven-003
-- ============================================================
INSERT INTO vehicles (vehicle_id, vendor_id, jenis, merek, model, tahun, plat_nomor, nomor_stnk, warna, status, tarif_per_jam, tarif_deposit, kapasitas, deskripsi, fitur, lokasi_lat, lokasi_lng, rating_avg, total_ulasan) VALUES
('veh-010','ven-001-0000-0000-000000000001','motor','Honda','Beat Street',2023,'AB 1010 RH','STNK-RH-005','Hitam Doff','available',45000,150000,2,'Honda Beat Street 2023 sporty matic','["GPS Tracking","Smart Lock","Asuransi","Helm Inkl."]',-7.7608,110.3808,4.5,42),
('veh-011','ven-001-0000-0000-000000000001','motor','Yamaha','Lexi 125',2022,'AB 1111 RH','STNK-RH-006','Merah Maroon','available',55000,150000,2,'Yamaha Lexi 125 cocok harian dan touring ringan','["GPS Tracking","Smart Lock","Asuransi","Helm Inkl.","USB Charger"]',-7.7612,110.3812,4.6,38),
('veh-012','ven-002-0000-0000-000000000002','motor','Honda','Spacy',2022,'AB 1212 MK','STNK-MK-004','Hijau Tosca','available',40000,100000,2,'Honda Spacy ringan irit untuk dalam kota','["GPS Tracking","Smart Lock","Asuransi","Helm Inkl."]',-7.7955,110.3705,4.2,27),
('veh-013','ven-002-0000-0000-000000000002','motor','Yamaha','Fino 125',2023,'AB 1313 MK','STNK-MK-005','Pink Pastel','available',42000,100000,2,'Yamaha Fino 125 classic style retro','["GPS Tracking","Smart Lock","Asuransi","Helm Inkl."]',-7.7948,110.3702,4.3,31),
('veh-014','ven-003-0000-0000-000000000003','motor','Yamaha','XMAX 250',2023,'AB 1414 TJ','STNK-TJ-003','Hitam Matte','available',80000,200000,2,'Yamaha XMAX 250 maxi scooter premium','["GPS Tracking","Smart Lock","Asuransi","Helm Inkl.","USB Charger","Top Box"]',-7.8005,110.3755,4.8,19),
('veh-015','ven-003-0000-0000-000000000003','motor','Honda','CB150R Streetfire',2022,'AB 1515 TJ','STNK-TJ-004','Merah Racing','available',70000,180000,2,'Honda CB150R Streetfire naked bike sporty','["GPS Tracking","Smart Lock","Asuransi","Helm Inkl.","USB Charger"]',-7.8012,110.3762,4.5,24);

-- ============================================================
-- SET TARIF PER HARI untuk kendaraan baru
-- ============================================================
UPDATE vehicles SET tarif_per_hari = 80000  WHERE vehicle_id = 'veh-010'; -- Honda Beat Street
UPDATE vehicles SET tarif_per_hari = 95000  WHERE vehicle_id = 'veh-011'; -- Yamaha Lexi 125
UPDATE vehicles SET tarif_per_hari = 75000  WHERE vehicle_id = 'veh-012'; -- Honda Spacy
UPDATE vehicles SET tarif_per_hari = 78000  WHERE vehicle_id = 'veh-013'; -- Yamaha Fino 125
UPDATE vehicles SET tarif_per_hari = 150000 WHERE vehicle_id = 'veh-014'; -- Yamaha XMAX 250
UPDATE vehicles SET tarif_per_hari = 130000 WHERE vehicle_id = 'veh-015'; -- Honda CB150R Streetfire

-- ============================================================
-- BOOKINGS HISTORIS: 60 booking selesai (Nov 2025 - Mei 2026)
-- Status: completed | Distribusi: 24 ven-001, 20 ven-002, 16 ven-003
-- ============================================================
INSERT INTO bookings (booking_id, user_id, vehicle_id, geofence_id, waktu_mulai, waktu_selesai, durasi_jam, status_booking, metode_pengambilan) VALUES
('bkn-061-0000-0000-000000000061','usr-027-0000-0000-000000000027','veh-013','geo-005-0000-0000-000000000005',NOW() - INTERVAL 180 DAY,NOW() - INTERVAL 180 DAY + INTERVAL 8 HOUR,8,'completed','diantar'),
('bkn-060-0000-0000-000000000060','usr-002-0000-0000-000000000002','veh-002','geo-003-0000-0000-000000000003',NOW() - INTERVAL 176 DAY,NOW() - INTERVAL 176 DAY + INTERVAL 48 HOUR,48,'completed','ambil_sendiri'),
('bkn-059-0000-0000-000000000059','usr-030-0000-0000-000000000030','veh-001','geo-003-0000-0000-000000000003',NOW() - INTERVAL 172 DAY,NOW() - INTERVAL 172 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-058-0000-0000-000000000058','usr-011-0000-0000-000000000011','veh-008','geo-004-0000-0000-000000000004',NOW() - INTERVAL 167 DAY,NOW() - INTERVAL 167 DAY + INTERVAL 8 HOUR,8,'completed','ambil_sendiri'),
('bkn-057-0000-0000-000000000057','usr-029-0000-0000-000000000029','veh-010','geo-001-0000-0000-000000000001',NOW() - INTERVAL 162 DAY,NOW() - INTERVAL 162 DAY + INTERVAL 36 HOUR,36,'completed','ambil_sendiri'),
('bkn-056-0000-0000-000000000056','usr-022-0000-0000-000000000022','veh-004','geo-006-0000-0000-000000000006',NOW() - INTERVAL 157 DAY,NOW() - INTERVAL 157 DAY + INTERVAL 36 HOUR,36,'completed','ambil_sendiri'),
('bkn-055-0000-0000-000000000055','usr-026-0000-0000-000000000026','veh-004','geo-005-0000-0000-000000000005',NOW() - INTERVAL 152 DAY,NOW() - INTERVAL 152 DAY + INTERVAL 6 HOUR,6,'completed','ambil_sendiri'),
('bkn-054-0000-0000-000000000054','usr-014-0000-0000-000000000014','veh-003','geo-003-0000-0000-000000000003',NOW() - INTERVAL 147 DAY,NOW() - INTERVAL 147 DAY + INTERVAL 6 HOUR,6,'completed','ambil_sendiri'),
('bkn-053-0000-0000-000000000053','usr-004-0000-0000-000000000004','veh-015','geo-004-0000-0000-000000000004',NOW() - INTERVAL 142 DAY,NOW() - INTERVAL 142 DAY + INTERVAL 12 HOUR,12,'completed','ambil_sendiri'),
('bkn-052-0000-0000-000000000052','usr-026-0000-0000-000000000026','veh-002','geo-005-0000-0000-000000000005',NOW() - INTERVAL 137 DAY,NOW() - INTERVAL 137 DAY + INTERVAL 24 HOUR,24,'completed','diantar'),
('bkn-051-0000-0000-000000000051','usr-014-0000-0000-000000000014','veh-013','geo-003-0000-0000-000000000003',NOW() - INTERVAL 132 DAY,NOW() - INTERVAL 132 DAY + INTERVAL 18 HOUR,18,'completed','diantar'),
('bkn-050-0000-0000-000000000050','usr-008-0000-0000-000000000008','veh-009','geo-004-0000-0000-000000000004',NOW() - INTERVAL 127 DAY,NOW() - INTERVAL 127 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-049-0000-0000-000000000049','usr-023-0000-0000-000000000023','veh-007','geo-002-0000-0000-000000000002',NOW() - INTERVAL 122 DAY,NOW() - INTERVAL 122 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-048-0000-0000-000000000048','usr-027-0000-0000-000000000027','veh-002','geo-006-0000-0000-000000000006',NOW() - INTERVAL 117 DAY,NOW() - INTERVAL 117 DAY + INTERVAL 24 HOUR,24,'completed','diantar'),
('bkn-047-0000-0000-000000000047','usr-023-0000-0000-000000000023','veh-012','geo-002-0000-0000-000000000002',NOW() - INTERVAL 112 DAY,NOW() - INTERVAL 112 DAY + INTERVAL 12 HOUR,12,'completed','ambil_sendiri'),
('bkn-046-0000-0000-000000000046','usr-023-0000-0000-000000000023','veh-005','geo-002-0000-0000-000000000002',NOW() - INTERVAL 107 DAY,NOW() - INTERVAL 107 DAY + INTERVAL 48 HOUR,48,'completed','ambil_sendiri'),
('bkn-045-0000-0000-000000000045','usr-022-0000-0000-000000000022','veh-001','geo-001-0000-0000-000000000001',NOW() - INTERVAL 103 DAY,NOW() - INTERVAL 103 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-044-0000-0000-000000000044','usr-002-0000-0000-000000000002','veh-015','geo-005-0000-0000-000000000005',NOW() - INTERVAL 100 DAY,NOW() - INTERVAL 100 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-043-0000-0000-000000000043','usr-021-0000-0000-000000000021','veh-008','geo-004-0000-0000-000000000004',NOW() - INTERVAL 96 DAY,NOW() - INTERVAL 96 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-042-0000-0000-000000000042','usr-029-0000-0000-000000000029','veh-004','geo-003-0000-0000-000000000003',NOW() - INTERVAL 93 DAY,NOW() - INTERVAL 93 DAY + INTERVAL 36 HOUR,36,'completed','diantar'),
('bkn-041-0000-0000-000000000041','usr-026-0000-0000-000000000026','veh-014','geo-003-0000-0000-000000000003',NOW() - INTERVAL 90 DAY,NOW() - INTERVAL 90 DAY + INTERVAL 12 HOUR,12,'completed','ambil_sendiri'),
('bkn-040-0000-0000-000000000040','usr-020-0000-0000-000000000020','veh-007','geo-002-0000-0000-000000000002',NOW() - INTERVAL 89 DAY,NOW() - INTERVAL 89 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-039-0000-0000-000000000039','usr-010-0000-0000-000000000010','veh-013','geo-005-0000-0000-000000000005',NOW() - INTERVAL 87 DAY,NOW() - INTERVAL 87 DAY + INTERVAL 48 HOUR,48,'completed','ambil_sendiri'),
('bkn-038-0000-0000-000000000038','usr-022-0000-0000-000000000022','veh-007','geo-003-0000-0000-000000000003',NOW() - INTERVAL 85 DAY,NOW() - INTERVAL 85 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-037-0000-0000-000000000037','usr-028-0000-0000-000000000028','veh-003','geo-006-0000-0000-000000000006',NOW() - INTERVAL 82 DAY,NOW() - INTERVAL 82 DAY + INTERVAL 24 HOUR,24,'completed','diantar'),
('bkn-036-0000-0000-000000000036','usr-028-0000-0000-000000000028','veh-009','geo-004-0000-0000-000000000004',NOW() - INTERVAL 78 DAY,NOW() - INTERVAL 78 DAY + INTERVAL 8 HOUR,8,'completed','ambil_sendiri'),
('bkn-035-0000-0000-000000000035','usr-030-0000-0000-000000000030','veh-005','geo-002-0000-0000-000000000002',NOW() - INTERVAL 75 DAY,NOW() - INTERVAL 75 DAY + INTERVAL 24 HOUR,24,'completed','diantar'),
('bkn-034-0000-0000-000000000034','usr-028-0000-0000-000000000028','veh-012','geo-005-0000-0000-000000000005',NOW() - INTERVAL 72 DAY,NOW() - INTERVAL 72 DAY + INTERVAL 48 HOUR,48,'completed','diantar'),
('bkn-033-0000-0000-000000000033','usr-013-0000-0000-000000000013','veh-006','geo-002-0000-0000-000000000002',NOW() - INTERVAL 68 DAY,NOW() - INTERVAL 68 DAY + INTERVAL 36 HOUR,36,'completed','ambil_sendiri'),
('bkn-032-0000-0000-000000000032','usr-016-0000-0000-000000000016','veh-010','geo-005-0000-0000-000000000005',NOW() - INTERVAL 65 DAY,NOW() - INTERVAL 65 DAY + INTERVAL 48 HOUR,48,'completed','diantar'),
('bkn-031-0000-0000-000000000031','usr-024-0000-0000-000000000024','veh-014','geo-005-0000-0000-000000000005',NOW() - INTERVAL 62 DAY,NOW() - INTERVAL 62 DAY + INTERVAL 8 HOUR,8,'completed','ambil_sendiri'),
('bkn-030-0000-0000-000000000030','usr-020-0000-0000-000000000020','veh-005','geo-002-0000-0000-000000000002',NOW() - INTERVAL 58 DAY,NOW() - INTERVAL 58 DAY + INTERVAL 8 HOUR,8,'completed','ambil_sendiri'),
('bkn-029-0000-0000-000000000029','usr-001-0000-0000-000000000001','veh-008','geo-003-0000-0000-000000000003',NOW() - INTERVAL 55 DAY,NOW() - INTERVAL 55 DAY + INTERVAL 8 HOUR,8,'completed','ambil_sendiri'),
('bkn-028-0000-0000-000000000028','usr-003-0000-0000-000000000003','veh-001','geo-003-0000-0000-000000000003',NOW() - INTERVAL 52 DAY,NOW() - INTERVAL 52 DAY + INTERVAL 48 HOUR,48,'completed','ambil_sendiri'),
('bkn-027-0000-0000-000000000027','usr-016-0000-0000-000000000016','veh-005','geo-002-0000-0000-000000000002',NOW() - INTERVAL 50 DAY,NOW() - INTERVAL 50 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-026-0000-0000-000000000026','usr-021-0000-0000-000000000021','veh-013','geo-002-0000-0000-000000000002',NOW() - INTERVAL 48 DAY,NOW() - INTERVAL 48 DAY + INTERVAL 12 HOUR,12,'completed','ambil_sendiri'),
('bkn-025-0000-0000-000000000025','usr-007-0000-0000-000000000007','veh-011','geo-006-0000-0000-000000000006',NOW() - INTERVAL 45 DAY,NOW() - INTERVAL 45 DAY + INTERVAL 36 HOUR,36,'completed','diantar'),
('bkn-024-0000-0000-000000000024','usr-030-0000-0000-000000000030','veh-015','geo-005-0000-0000-000000000005',NOW() - INTERVAL 43 DAY,NOW() - INTERVAL 43 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-023-0000-0000-000000000023','usr-001-0000-0000-000000000001','veh-003','geo-006-0000-0000-000000000006',NOW() - INTERVAL 40 DAY,NOW() - INTERVAL 40 DAY + INTERVAL 12 HOUR,12,'completed','ambil_sendiri'),
('bkn-022-0000-0000-000000000022','usr-028-0000-0000-000000000028','veh-006','geo-005-0000-0000-000000000005',NOW() - INTERVAL 37 DAY,NOW() - INTERVAL 37 DAY + INTERVAL 10 HOUR,10,'completed','ambil_sendiri'),
('bkn-021-0000-0000-000000000021','usr-012-0000-0000-000000000012','veh-002','geo-003-0000-0000-000000000003',NOW() - INTERVAL 34 DAY,NOW() - INTERVAL 34 DAY + INTERVAL 48 HOUR,48,'completed','diantar'),
('bkn-020-0000-0000-000000000020','usr-017-0000-0000-000000000017','veh-009','geo-003-0000-0000-000000000003',NOW() - INTERVAL 32 DAY,NOW() - INTERVAL 32 DAY + INTERVAL 36 HOUR,36,'completed','ambil_sendiri'),
('bkn-019-0000-0000-000000000019','usr-018-0000-0000-000000000018','veh-011','geo-001-0000-0000-000000000001',NOW() - INTERVAL 30 DAY,NOW() - INTERVAL 30 DAY + INTERVAL 72 HOUR,72,'completed','diantar'),
('bkn-018-0000-0000-000000000018','usr-029-0000-0000-000000000029','veh-001','geo-001-0000-0000-000000000001',NOW() - INTERVAL 28 DAY,NOW() - INTERVAL 28 DAY + INTERVAL 12 HOUR,12,'completed','ambil_sendiri'),
('bkn-017-0000-0000-000000000017','usr-025-0000-0000-000000000025','veh-009','geo-005-0000-0000-000000000005',NOW() - INTERVAL 26 DAY,NOW() - INTERVAL 26 DAY + INTERVAL 18 HOUR,18,'completed','ambil_sendiri'),
('bkn-016-0000-0000-000000000016','usr-019-0000-0000-000000000019','veh-006','geo-003-0000-0000-000000000003',NOW() - INTERVAL 25 DAY,NOW() - INTERVAL 25 DAY + INTERVAL 6 HOUR,6,'completed','ambil_sendiri'),
('bkn-015-0000-0000-000000000015','usr-012-0000-0000-000000000012','veh-008','geo-003-0000-0000-000000000003',NOW() - INTERVAL 24 DAY,NOW() - INTERVAL 24 DAY + INTERVAL 48 HOUR,48,'completed','ambil_sendiri'),
('bkn-014-0000-0000-000000000014','usr-018-0000-0000-000000000018','veh-006','geo-002-0000-0000-000000000002',NOW() - INTERVAL 22 DAY,NOW() - INTERVAL 22 DAY + INTERVAL 24 HOUR,24,'completed','ambil_sendiri'),
('bkn-013-0000-0000-000000000013','usr-013-0000-0000-000000000013','veh-012','geo-005-0000-0000-000000000005',NOW() - INTERVAL 20 DAY,NOW() - INTERVAL 20 DAY + INTERVAL 18 HOUR,18,'completed','ambil_sendiri'),
('bkn-012-0000-0000-000000000012','usr-024-0000-0000-000000000024','veh-003','geo-003-0000-0000-000000000003',NOW() - INTERVAL 18 DAY,NOW() - INTERVAL 18 DAY + INTERVAL 36 HOUR,36,'completed','ambil_sendiri'),
('bkn-011-0000-0000-000000000011','usr-006-0000-0000-000000000006','veh-010','geo-001-0000-0000-000000000001',NOW() - INTERVAL 16 DAY,NOW() - INTERVAL 16 DAY + INTERVAL 72 HOUR,72,'completed','ambil_sendiri'),
('bkn-010-0000-0000-000000000010','usr-002-0000-0000-000000000002','veh-007','geo-003-0000-0000-000000000003',NOW() - INTERVAL 14 DAY,NOW() - INTERVAL 14 DAY + INTERVAL 10 HOUR,10,'completed','diantar'),
('bkn-009-0000-0000-000000000009','usr-025-0000-0000-000000000025','veh-015','geo-005-0000-0000-000000000005',NOW() - INTERVAL 12 DAY,NOW() - INTERVAL 12 DAY + INTERVAL 8 HOUR,8,'completed','ambil_sendiri'),
('bkn-008-0000-0000-000000000008','usr-029-0000-0000-000000000029','veh-014','geo-003-0000-0000-000000000003',NOW() - INTERVAL 11 DAY,NOW() - INTERVAL 11 DAY + INTERVAL 48 HOUR,48,'completed','ambil_sendiri'),
('bkn-007-0000-0000-000000000007','usr-011-0000-0000-000000000011','veh-011','geo-005-0000-0000-000000000005',NOW() - INTERVAL 9 DAY,NOW() - INTERVAL 9 DAY + INTERVAL 36 HOUR,36,'completed','ambil_sendiri'),
('bkn-006-0000-0000-000000000006','usr-025-0000-0000-000000000025','veh-010','geo-006-0000-0000-000000000006',NOW() - INTERVAL 7 DAY,NOW() - INTERVAL 7 DAY + INTERVAL 24 HOUR,24,'completed','diantar'),
('bkn-005-0000-0000-000000000005','usr-019-0000-0000-000000000019','veh-003','geo-006-0000-0000-000000000006',NOW() - INTERVAL 5 DAY,NOW() - INTERVAL 5 DAY + INTERVAL 48 HOUR,48,'completed','ambil_sendiri'),
('bkn-004-0000-0000-000000000004','usr-015-0000-0000-000000000015','veh-014','geo-004-0000-0000-000000000004',NOW() - INTERVAL 3 DAY,NOW() - INTERVAL 3 DAY + INTERVAL 48 HOUR,48,'completed','ambil_sendiri'),
('bkn-003-0000-0000-000000000003','usr-001-0000-0000-000000000001','veh-011','geo-001-0000-0000-000000000001',NOW() - INTERVAL 2 DAY,NOW() - INTERVAL 2 DAY + INTERVAL 6 HOUR,6,'completed','ambil_sendiri'),
('bkn-002-0000-0000-000000000002','usr-004-0000-0000-000000000004','veh-012','geo-002-0000-0000-000000000002',NOW() - INTERVAL 1 DAY,NOW() - INTERVAL 1 DAY + INTERVAL 36 HOUR,36,'completed','diantar');

-- ============================================================
-- PAYMENTS: 60 payment captured (1 per booking)
-- ============================================================
INSERT INTO payments (payment_id, booking_id, biaya_sewa, deposit_virtual, total_bayar, metode_bayar, status_payment, paid_at) VALUES
('pay-061-0000-0000-000000000061','bkn-061-0000-0000-000000000061',336000,100000,436000,'bca_va','captured',NOW() - INTERVAL 180 DAY),
('pay-060-0000-0000-000000000060','bkn-060-0000-0000-000000000060',180000,150000,330000,'gopay','captured',NOW() - INTERVAL 176 DAY),
('pay-059-0000-0000-000000000059','bkn-059-0000-0000-000000000059',80000,150000,230000,'gopay','captured',NOW() - INTERVAL 172 DAY),
('pay-058-0000-0000-000000000058','bkn-058-0000-0000-000000000058',440000,150000,590000,'gopay','captured',NOW() - INTERVAL 167 DAY),
('pay-057-0000-0000-000000000057','bkn-057-0000-0000-000000000057',620000,150000,770000,'debit','captured',NOW() - INTERVAL 162 DAY),
('pay-056-0000-0000-000000000056','bkn-056-0000-0000-000000000056',830000,180000,1010000,'debit','captured',NOW() - INTERVAL 157 DAY),
('pay-055-0000-0000-000000000055','bkn-055-0000-0000-000000000055',360000,180000,540000,'debit','captured',NOW() - INTERVAL 152 DAY),
('pay-054-0000-0000-000000000054','bkn-054-0000-0000-000000000054',390000,200000,590000,'bca_va','captured',NOW() - INTERVAL 147 DAY),
('pay-053-0000-0000-000000000053','bkn-053-0000-0000-000000000053',840000,180000,1020000,'bca_va','captured',NOW() - INTERVAL 142 DAY),
('pay-052-0000-0000-000000000052','bkn-052-0000-0000-000000000052',90000,150000,240000,'debit','captured',NOW() - INTERVAL 137 DAY),
('pay-051-0000-0000-000000000051','bkn-051-0000-0000-000000000051',756000,100000,856000,'debit','captured',NOW() - INTERVAL 132 DAY),
('pay-050-0000-0000-000000000050','bkn-050-0000-0000-000000000050',110000,150000,260000,'debit','captured',NOW() - INTERVAL 127 DAY),
('pay-049-0000-0000-000000000049','bkn-049-0000-0000-000000000049',75000,100000,175000,'gopay','captured',NOW() - INTERVAL 122 DAY),
('pay-048-0000-0000-000000000048','bkn-048-0000-0000-000000000048',90000,150000,240000,'debit','captured',NOW() - INTERVAL 117 DAY),
('pay-047-0000-0000-000000000047','bkn-047-0000-0000-000000000047',480000,100000,580000,'bca_va','captured',NOW() - INTERVAL 112 DAY),
('pay-046-0000-0000-000000000046','bkn-046-0000-0000-000000000046',150000,100000,250000,'bca_va','captured',NOW() - INTERVAL 107 DAY),
('pay-045-0000-0000-000000000045','bkn-045-0000-0000-000000000045',80000,150000,230000,'debit','captured',NOW() - INTERVAL 103 DAY),
('pay-044-0000-0000-000000000044','bkn-044-0000-0000-000000000044',130000,180000,310000,'gopay','captured',NOW() - INTERVAL 100 DAY),
('pay-043-0000-0000-000000000043','bkn-043-0000-0000-000000000043',100000,150000,250000,'debit','captured',NOW() - INTERVAL 96 DAY),
('pay-042-0000-0000-000000000042','bkn-042-0000-0000-000000000042',830000,180000,1010000,'mandiri_va','captured',NOW() - INTERVAL 93 DAY),
('pay-041-0000-0000-000000000041','bkn-041-0000-0000-000000000041',960000,200000,1160000,'debit','captured',NOW() - INTERVAL 90 DAY),
('pay-040-0000-0000-000000000040','bkn-040-0000-0000-000000000040',75000,100000,175000,'debit','captured',NOW() - INTERVAL 89 DAY),
('pay-039-0000-0000-000000000039','bkn-039-0000-0000-000000000039',156000,100000,256000,'gopay','captured',NOW() - INTERVAL 87 DAY),
('pay-038-0000-0000-000000000038','bkn-038-0000-0000-000000000038',75000,100000,175000,'gopay','captured',NOW() - INTERVAL 85 DAY),
('pay-037-0000-0000-000000000037','bkn-037-0000-0000-000000000037',120000,200000,320000,'gopay','captured',NOW() - INTERVAL 82 DAY),
('pay-036-0000-0000-000000000036','bkn-036-0000-0000-000000000036',480000,150000,630000,'debit','captured',NOW() - INTERVAL 78 DAY),
('pay-035-0000-0000-000000000035','bkn-035-0000-0000-000000000035',75000,100000,175000,'debit','captured',NOW() - INTERVAL 75 DAY),
('pay-034-0000-0000-000000000034','bkn-034-0000-0000-000000000034',150000,100000,250000,'gopay','captured',NOW() - INTERVAL 72 DAY),
('pay-033-0000-0000-000000000033','bkn-033-0000-0000-000000000033',620000,100000,720000,'debit','captured',NOW() - INTERVAL 68 DAY),
('pay-032-0000-0000-000000000032','bkn-032-0000-0000-000000000032',160000,150000,310000,'gopay','captured',NOW() - INTERVAL 65 DAY),
('pay-031-0000-0000-000000000031','bkn-031-0000-0000-000000000031',640000,200000,840000,'debit','captured',NOW() - INTERVAL 62 DAY),
('pay-030-0000-0000-000000000030','bkn-030-0000-0000-000000000030',320000,100000,420000,'debit','captured',NOW() - INTERVAL 58 DAY),
('pay-029-0000-0000-000000000029','bkn-029-0000-0000-000000000029',440000,150000,590000,'debit','captured',NOW() - INTERVAL 55 DAY),
('pay-028-0000-0000-000000000028','bkn-028-0000-0000-000000000028',160000,150000,310000,'debit','captured',NOW() - INTERVAL 52 DAY),
('pay-027-0000-0000-000000000027','bkn-027-0000-0000-000000000027',75000,100000,175000,'debit','captured',NOW() - INTERVAL 50 DAY),
('pay-026-0000-0000-000000000026','bkn-026-0000-0000-000000000026',504000,100000,604000,'debit','captured',NOW() - INTERVAL 48 DAY),
('pay-025-0000-0000-000000000025','bkn-025-0000-0000-000000000025',755000,150000,905000,'debit','captured',NOW() - INTERVAL 45 DAY),
('pay-024-0000-0000-000000000024','bkn-024-0000-0000-000000000024',130000,180000,310000,'debit','captured',NOW() - INTERVAL 43 DAY),
('pay-023-0000-0000-000000000023','bkn-023-0000-0000-000000000023',780000,200000,980000,'gopay','captured',NOW() - INTERVAL 40 DAY),
('pay-022-0000-0000-000000000022','bkn-022-0000-0000-000000000022',450000,100000,550000,'mandiri_va','captured',NOW() - INTERVAL 37 DAY),
('pay-021-0000-0000-000000000021','bkn-021-0000-0000-000000000021',180000,150000,330000,'gopay','captured',NOW() - INTERVAL 34 DAY),
('pay-020-0000-0000-000000000020','bkn-020-0000-0000-000000000020',830000,150000,980000,'bca_va','captured',NOW() - INTERVAL 32 DAY),
('pay-019-0000-0000-000000000019','bkn-019-0000-0000-000000000019',285000,150000,435000,'debit','captured',NOW() - INTERVAL 30 DAY),
('pay-018-0000-0000-000000000018','bkn-018-0000-0000-000000000018',540000,150000,690000,'gopay','captured',NOW() - INTERVAL 28 DAY),
('pay-017-0000-0000-000000000017','bkn-017-0000-0000-000000000017',1080000,150000,1230000,'mandiri_va','captured',NOW() - INTERVAL 26 DAY),
('pay-016-0000-0000-000000000016','bkn-016-0000-0000-000000000016',270000,100000,370000,'bca_va','captured',NOW() - INTERVAL 25 DAY),
('pay-015-0000-0000-000000000015','bkn-015-0000-0000-000000000015',200000,150000,350000,'gopay','captured',NOW() - INTERVAL 24 DAY),
('pay-014-0000-0000-000000000014','bkn-014-0000-0000-000000000014',80000,100000,180000,'debit','captured',NOW() - INTERVAL 22 DAY),
('pay-013-0000-0000-000000000013','bkn-013-0000-0000-000000000013',720000,100000,820000,'bca_va','captured',NOW() - INTERVAL 20 DAY),
('pay-012-0000-0000-000000000012','bkn-012-0000-0000-000000000012',900000,200000,1100000,'mandiri_va','captured',NOW() - INTERVAL 18 DAY),
('pay-011-0000-0000-000000000011','bkn-011-0000-0000-000000000011',240000,150000,390000,'gopay','captured',NOW() - INTERVAL 16 DAY),
('pay-010-0000-0000-000000000010','bkn-010-0000-0000-000000000010',400000,100000,500000,'debit','captured',NOW() - INTERVAL 14 DAY),
('pay-009-0000-0000-000000000009','bkn-009-0000-0000-000000000009',560000,180000,740000,'bca_va','captured',NOW() - INTERVAL 12 DAY),
('pay-008-0000-0000-000000000008','bkn-008-0000-0000-000000000008',300000,200000,500000,'debit','captured',NOW() - INTERVAL 11 DAY),
('pay-007-0000-0000-000000000007','bkn-007-0000-0000-000000000007',755000,150000,905000,'debit','captured',NOW() - INTERVAL 9 DAY),
('pay-006-0000-0000-000000000006','bkn-006-0000-0000-000000000006',80000,150000,230000,'debit','captured',NOW() - INTERVAL 7 DAY),
('pay-005-0000-0000-000000000005','bkn-005-0000-0000-000000000005',240000,200000,440000,'debit','captured',NOW() - INTERVAL 5 DAY),
('pay-004-0000-0000-000000000004','bkn-004-0000-0000-000000000004',300000,200000,500000,'debit','captured',NOW() - INTERVAL 3 DAY),
('pay-003-0000-0000-000000000003','bkn-003-0000-0000-000000000003',330000,150000,480000,'bca_va','captured',NOW() - INTERVAL 2 DAY),
('pay-002-0000-0000-000000000002','bkn-002-0000-0000-000000000002',555000,100000,655000,'gopay','captured',NOW() - INTERVAL 1 DAY);

-- ============================================================
-- TC-UI-012: Booking dengan DENDA overtime (uji tombol "Bebaskan" vendor)
-- Honda Beat (Rental Pak Haji) disewa Demo Penyewa, dikembalikan 5 jam terlambat.
-- Denda Rp25.000 dipotong dari deposit (status 'deducted'); vendor dapat membebaskannya.
-- ============================================================
INSERT INTO bookings (booking_id, user_id, vehicle_id, geofence_id, waktu_mulai, waktu_selesai, waktu_aktual_kembali, durasi_jam, status_booking, geofence_validated, metode_pengambilan) VALUES
('bkn-062-0000-0000-000000000062','usr-004-0000-0000-000000000004','veh-001','geo-001-0000-0000-000000000001',NOW() - INTERVAL 4 DAY,NOW() - INTERVAL 3 DAY,NOW() - INTERVAL 3 DAY + INTERVAL 5 HOUR,24,'completed',1,'ambil_sendiri');

INSERT INTO payments (payment_id, booking_id, biaya_sewa, deposit_virtual, total_bayar, metode_bayar, status_payment, refund_amount, deposit_dilepas_at, paid_at) VALUES
('pay-062-0000-0000-000000000062','bkn-062-0000-0000-000000000062',80000,150000,230000,'gopay','partially_refunded',125000,NOW() - INTERVAL 3 DAY + INTERVAL 5 HOUR,NOW() - INTERVAL 4 DAY);

INSERT INTO penalties (penalty_id, booking_id, durasi_overtime_menit, tarif_per_jam_denda, nominal_denda, status_potong, auto_deduct_at, keterangan) VALUES
('pen-001-0000-0000-000000000001','bkn-062-0000-0000-000000000062',300,5000.00,25000,'deducted',NOW() - INTERVAL 3 DAY + INTERVAL 5 HOUR,'Overtime 5 jam saat pengembalian Honda Beat 2023');

-- ============================================================
-- REVIEWS: 40 dari 60 booking diberi ulasan
-- ============================================================
INSERT INTO reviews (review_id, booking_id, user_id, vehicle_id, rating, komentar, created_at) VALUES
('rev-001-0000-0000-000000000001','bkn-061-0000-0000-000000000061','usr-027-0000-0000-000000000027','veh-013',4,'Motor bagus, hanya saja jok agak panas siang hari.',NOW() - INTERVAL 178 DAY),
('rev-002-0000-0000-000000000002','bkn-060-0000-0000-000000000060','usr-002-0000-0000-000000000002','veh-002',3,'Cukup, body ada baret kecil tapi tidak mengganggu.',NOW() - INTERVAL 171 DAY),
('rev-003-0000-0000-000000000003','bkn-059-0000-0000-000000000059','usr-030-0000-0000-000000000030','veh-001',4,'Pelayanan baik, motor sesuai foto, ban perlu pengecekan.',NOW() - INTERVAL 168 DAY),
('rev-004-0000-0000-000000000004','bkn-058-0000-0000-000000000058','usr-011-0000-0000-000000000011','veh-008',5,'Top markotop, motor sehat dan kencang untuk touring.',NOW() - INTERVAL 166 DAY),
('rev-005-0000-0000-000000000005','bkn-057-0000-0000-000000000057','usr-029-0000-0000-000000000029','veh-010',5,'Pelayanan vendor sangat cepat dan profesional.',NOW() - INTERVAL 158 DAY),
('rev-006-0000-0000-000000000006','bkn-056-0000-0000-000000000056','usr-022-0000-0000-000000000022','veh-004',3,'Standard saja, tidak ada masalah berarti.',NOW() - INTERVAL 154 DAY),
('rev-007-0000-0000-000000000007','bkn-055-0000-0000-000000000055','usr-026-0000-0000-000000000026','veh-004',5,'Pengalaman menyenangkan, smart unlock cepat. Akan sewa lagi.',NOW() - INTERVAL 151 DAY),
('rev-008-0000-0000-000000000008','bkn-054-0000-0000-000000000054','usr-014-0000-0000-000000000014','veh-003',4,'Cukup baik, harga sebanding dengan kualitas motor.',NOW() - INTERVAL 145 DAY),
('rev-009-0000-0000-000000000009','bkn-053-0000-0000-000000000053','usr-004-0000-0000-000000000004','veh-015',5,'Pengalaman menyenangkan, smart unlock cepat. Akan sewa lagi.',NOW() - INTERVAL 141 DAY),
('rev-010-0000-0000-000000000010','bkn-052-0000-0000-000000000052','usr-026-0000-0000-000000000026','veh-002',5,'Top markotop, motor sehat dan kencang untuk touring.',NOW() - INTERVAL 135 DAY),
('rev-011-0000-0000-000000000011','bkn-051-0000-0000-000000000051','usr-014-0000-0000-000000000014','veh-013',5,'Pelayanan vendor sangat cepat dan profesional.',NOW() - INTERVAL 131 DAY),
('rev-012-0000-0000-000000000012','bkn-050-0000-0000-000000000050','usr-008-0000-0000-000000000008','veh-009',5,'Motor mulus, oli baru diganti. Mantap!',NOW() - INTERVAL 123 DAY),
('rev-013-0000-0000-000000000013','bkn-049-0000-0000-000000000049','usr-023-0000-0000-000000000023','veh-007',4,'Cukup baik, harga sebanding dengan kualitas motor.',NOW() - INTERVAL 118 DAY),
('rev-014-0000-0000-000000000014','bkn-048-0000-0000-000000000048','usr-027-0000-0000-000000000027','veh-002',5,'Motor bersih, mesin halus, pelayanan ramah. Recommended!',NOW() - INTERVAL 115 DAY),
('rev-015-0000-0000-000000000015','bkn-047-0000-0000-000000000047','usr-023-0000-0000-000000000023','veh-012',5,'Kondisi prima, helm bersih, tidak ada kendala selama pakai.',NOW() - INTERVAL 109 DAY),
('rev-016-0000-0000-000000000016','bkn-046-0000-0000-000000000046','usr-023-0000-0000-000000000023','veh-005',4,'Motor bagus, hanya saja jok agak panas siang hari.',NOW() - INTERVAL 102 DAY),
('rev-017-0000-0000-000000000017','bkn-045-0000-0000-000000000045','usr-022-0000-0000-000000000022','veh-001',5,'Pengalaman menyenangkan, smart unlock cepat. Akan sewa lagi.',NOW() - INTERVAL 100 DAY),
('rev-018-0000-0000-000000000018','bkn-044-0000-0000-000000000044','usr-002-0000-0000-000000000002','veh-015',4,'Motor enak dipakai, helm full face bagus.',NOW() - INTERVAL 96 DAY),
('rev-019-0000-0000-000000000019','bkn-043-0000-0000-000000000043','usr-021-0000-0000-000000000021','veh-008',4,'Motor bagus, hanya saja jok agak panas siang hari.',NOW() - INTERVAL 93 DAY),
('rev-020-0000-0000-000000000020','bkn-042-0000-0000-000000000042','usr-029-0000-0000-000000000029','veh-004',4,'Motor bagus, hanya saja jok agak panas siang hari.',NOW() - INTERVAL 91 DAY),
('rev-021-0000-0000-000000000021','bkn-041-0000-0000-000000000041','usr-026-0000-0000-000000000026','veh-014',3,'Cukup, body ada baret kecil tapi tidak mengganggu.',NOW() - INTERVAL 88 DAY),
('rev-022-0000-0000-000000000022','bkn-040-0000-0000-000000000040','usr-020-0000-0000-000000000020','veh-007',5,'Pengalaman menyenangkan, smart unlock cepat. Akan sewa lagi.',NOW() - INTERVAL 86 DAY),
('rev-023-0000-0000-000000000023','bkn-039-0000-0000-000000000039','usr-010-0000-0000-000000000010','veh-013',4,'Pelayanan baik, motor sesuai foto, ban perlu pengecekan.',NOW() - INTERVAL 82 DAY),
('rev-024-0000-0000-000000000024','bkn-038-0000-0000-000000000038','usr-022-0000-0000-000000000022','veh-007',4,'Nyaman dipakai harian, asuransi memberi rasa aman.',NOW() - INTERVAL 81 DAY),
('rev-025-0000-0000-000000000025','bkn-037-0000-0000-000000000037','usr-028-0000-0000-000000000028','veh-003',5,'Sangat puas, motor irit dan nyaman untuk touring kota.',NOW() - INTERVAL 79 DAY),
('rev-026-0000-0000-000000000026','bkn-036-0000-0000-000000000036','usr-028-0000-0000-000000000028','veh-009',5,'Pelayanan ramah, motor terawat, akan kembali lagi.',NOW() - INTERVAL 76 DAY),
('rev-027-0000-0000-000000000027','bkn-035-0000-0000-000000000035','usr-030-0000-0000-000000000030','veh-005',5,'Recommended seller, motor selalu prima.',NOW() - INTERVAL 71 DAY),
('rev-028-0000-0000-000000000028','bkn-034-0000-0000-000000000034','usr-028-0000-0000-000000000028','veh-012',4,'Motor bagus, hanya saja jok agak panas siang hari.',NOW() - INTERVAL 69 DAY),
('rev-029-0000-0000-000000000029','bkn-033-0000-0000-000000000033','usr-013-0000-0000-000000000013','veh-006',4,'Overall oke, sedikit telat saat pengembalian deposit.',NOW() - INTERVAL 66 DAY),
('rev-030-0000-0000-000000000030','bkn-032-0000-0000-000000000032','usr-016-0000-0000-000000000016','veh-010',4,'Cukup baik, harga sebanding dengan kualitas motor.',NOW() - INTERVAL 62 DAY),
('rev-031-0000-0000-000000000031','bkn-031-0000-0000-000000000031','usr-024-0000-0000-000000000024','veh-014',4,'Overall oke, sedikit telat saat pengembalian deposit.',NOW() - INTERVAL 59 DAY),
('rev-032-0000-0000-000000000032','bkn-030-0000-0000-000000000030','usr-020-0000-0000-000000000020','veh-005',5,'Top markotop, motor sehat dan kencang untuk touring.',NOW() - INTERVAL 56 DAY),
('rev-033-0000-0000-000000000033','bkn-029-0000-0000-000000000029','usr-001-0000-0000-000000000001','veh-008',4,'Nyaman dipakai harian, asuransi memberi rasa aman.',NOW() - INTERVAL 53 DAY),
('rev-034-0000-0000-000000000034','bkn-028-0000-0000-000000000028','usr-003-0000-0000-000000000003','veh-001',4,'Overall oke, sedikit telat saat pengembalian deposit.',NOW() - INTERVAL 47 DAY),
('rev-035-0000-0000-000000000035','bkn-027-0000-0000-000000000027','usr-016-0000-0000-000000000016','veh-005',5,'Sangat puas, motor irit dan nyaman untuk touring kota.',NOW() - INTERVAL 47 DAY),
('rev-036-0000-0000-000000000036','bkn-026-0000-0000-000000000026','usr-021-0000-0000-000000000021','veh-013',5,'Pengalaman menyenangkan, smart unlock cepat. Akan sewa lagi.',NOW() - INTERVAL 46 DAY),
('rev-037-0000-0000-000000000037','bkn-025-0000-0000-000000000025','usr-007-0000-0000-000000000007','veh-011',4,'Nyaman dipakai harian, asuransi memberi rasa aman.',NOW() - INTERVAL 43 DAY),
('rev-038-0000-0000-000000000038','bkn-024-0000-0000-000000000024','usr-030-0000-0000-000000000030','veh-015',5,'Motor mulus, oli baru diganti. Mantap!',NOW() - INTERVAL 40 DAY),
('rev-039-0000-0000-000000000039','bkn-023-0000-0000-000000000023','usr-001-0000-0000-000000000001','veh-003',3,'Cukup, body ada baret kecil tapi tidak mengganggu.',NOW() - INTERVAL 39 DAY),
('rev-040-0000-0000-000000000040','bkn-022-0000-0000-000000000022','usr-028-0000-0000-000000000028','veh-006',4,'Nyaman dipakai harian, asuransi memberi rasa aman.',NOW() - INTERVAL 36 DAY);

-- ============================================================
-- SYNC rating_avg & total_ulasan berdasarkan reviews yang diseed
-- ============================================================
UPDATE vehicles SET
    rating_avg   = (SELECT ROUND(AVG(rating), 1) FROM reviews WHERE reviews.vehicle_id = vehicles.vehicle_id),
    total_ulasan = (SELECT COUNT(*) FROM reviews WHERE reviews.vehicle_id = vehicles.vehicle_id)
WHERE vehicle_id IN (SELECT DISTINCT vehicle_id FROM reviews);

-- ============================================================
-- TRUST LOGS: 10 user dengan aktivitas booking terbanyak
-- ============================================================
INSERT INTO trust_logs (user_id, parameter, delta_skor, skor_sebelum, skor_sesudah, keterangan, created_at) VALUES
('usr-029-0000-0000-000000000029','verifikasi_identitas',20,0,20,'NIK dan SIM C terverifikasi',NOW() - INTERVAL 175 DAY),
('usr-029-0000-0000-000000000029','sewa_selesai_tepat_waktu',10,20,30,'Sewa pertama selesai tepat waktu',NOW() - INTERVAL 150 DAY),
('usr-029-0000-0000-000000000029','sewa_selesai_tepat_waktu',10,30,40,'Sewa kedua selesai tepat waktu',NOW() - INTERVAL 120 DAY),
('usr-029-0000-0000-000000000029','riwayat_3x_bersih',30,40,70,'3 transaksi berturut tanpa pelanggaran',NOW() - INTERVAL 80 DAY),
('usr-029-0000-0000-000000000029','referral_pengguna',22,70,92,'Referral 2 pengguna baru',NOW() - INTERVAL 30 DAY),
('usr-028-0000-0000-000000000028','verifikasi_identitas',20,0,20,'NIK dan SIM C terverifikasi',NOW() - INTERVAL 175 DAY),
('usr-028-0000-0000-000000000028','sewa_selesai_tepat_waktu',10,20,30,'Sewa pertama selesai tepat waktu',NOW() - INTERVAL 150 DAY),
('usr-028-0000-0000-000000000028','sewa_selesai_tepat_waktu',10,30,40,'Sewa kedua selesai tepat waktu',NOW() - INTERVAL 120 DAY),
('usr-028-0000-0000-000000000028','riwayat_3x_bersih',30,40,70,'3 transaksi berturut tanpa pelanggaran',NOW() - INTERVAL 80 DAY),
('usr-028-0000-0000-000000000028','referral_pengguna',17,70,87,'Referral 2 pengguna baru',NOW() - INTERVAL 30 DAY),
('usr-002-0000-0000-000000000002','verifikasi_identitas',20,0,20,'NIK dan SIM C terverifikasi',NOW() - INTERVAL 175 DAY),
('usr-002-0000-0000-000000000002','sewa_selesai_tepat_waktu',10,20,30,'Sewa pertama selesai tepat waktu',NOW() - INTERVAL 150 DAY),
('usr-002-0000-0000-000000000002','sewa_selesai_tepat_waktu',10,30,40,'Sewa kedua selesai tepat waktu',NOW() - INTERVAL 120 DAY),
('usr-002-0000-0000-000000000002','riwayat_3x_bersih',30,40,70,'3 transaksi berturut tanpa pelanggaran',NOW() - INTERVAL 80 DAY),
('usr-002-0000-0000-000000000002','referral_pengguna',25,70,95,'Referral 3 pengguna baru',NOW() - INTERVAL 30 DAY),
('usr-030-0000-0000-000000000030','verifikasi_identitas',20,0,20,'NIK dan SIM C terverifikasi',NOW() - INTERVAL 175 DAY),
('usr-030-0000-0000-000000000030','sewa_selesai_tepat_waktu',10,20,30,'Sewa pertama selesai tepat waktu',NOW() - INTERVAL 150 DAY),
('usr-030-0000-0000-000000000030','sewa_selesai_tepat_waktu',10,30,40,'Sewa kedua selesai tepat waktu',NOW() - INTERVAL 120 DAY),
('usr-030-0000-0000-000000000030','riwayat_3x_bersih',30,40,70,'3 transaksi berturut tanpa pelanggaran',NOW() - INTERVAL 80 DAY),
('usr-030-0000-0000-000000000030','referral_pengguna',28,70,98,'Referral 3 pengguna baru',NOW() - INTERVAL 30 DAY),
('usr-022-0000-0000-000000000022','verifikasi_identitas',20,0,20,'NIK dan SIM C terverifikasi',NOW() - INTERVAL 175 DAY),
('usr-022-0000-0000-000000000022','sewa_selesai_tepat_waktu',10,20,30,'Sewa pertama selesai tepat waktu',NOW() - INTERVAL 150 DAY),
('usr-022-0000-0000-000000000022','sewa_selesai_tepat_waktu',10,30,40,'Sewa kedua selesai tepat waktu',NOW() - INTERVAL 120 DAY),
('usr-022-0000-0000-000000000022','riwayat_3x_bersih',30,40,70,'3 transaksi berturut tanpa pelanggaran',NOW() - INTERVAL 80 DAY),
('usr-022-0000-0000-000000000022','referral_pengguna',3,70,73,'Referral 1 pengguna baru',NOW() - INTERVAL 30 DAY),
('usr-026-0000-0000-000000000026','verifikasi_identitas',20,0,20,'NIK dan SIM C terverifikasi',NOW() - INTERVAL 175 DAY),
('usr-026-0000-0000-000000000026','sewa_selesai_tepat_waktu',10,20,30,'Sewa pertama selesai tepat waktu',NOW() - INTERVAL 150 DAY),
('usr-026-0000-0000-000000000026','sewa_selesai_tepat_waktu',10,30,40,'Sewa kedua selesai tepat waktu',NOW() - INTERVAL 120 DAY),
('usr-026-0000-0000-000000000026','riwayat_3x_bersih',30,40,70,'3 transaksi berturut tanpa pelanggaran',NOW() - INTERVAL 80 DAY),
('usr-026-0000-0000-000000000026','referral_pengguna',12,70,82,'Referral 2 pengguna baru',NOW() - INTERVAL 30 DAY),
('usr-023-0000-0000-000000000023','verifikasi_identitas',20,0,20,'NIK dan SIM C terverifikasi',NOW() - INTERVAL 175 DAY),
('usr-023-0000-0000-000000000023','sewa_selesai_tepat_waktu',10,20,30,'Sewa pertama selesai tepat waktu',NOW() - INTERVAL 150 DAY),
('usr-023-0000-0000-000000000023','sewa_selesai_tepat_waktu',10,30,40,'Sewa kedua selesai tepat waktu',NOW() - INTERVAL 120 DAY),
('usr-023-0000-0000-000000000023','riwayat_3x_bersih',30,40,70,'3 transaksi berturut tanpa pelanggaran',NOW() - INTERVAL 80 DAY),
('usr-023-0000-0000-000000000023','referral_pengguna',5,70,75,'Referral 1 pengguna baru',NOW() - INTERVAL 30 DAY),
('usr-001-0000-0000-000000000001','verifikasi_identitas',20,0,20,'NIK dan SIM C terverifikasi',NOW() - INTERVAL 175 DAY),
('usr-001-0000-0000-000000000001','sewa_selesai_tepat_waktu',10,20,30,'Sewa pertama selesai tepat waktu',NOW() - INTERVAL 150 DAY),
('usr-001-0000-0000-000000000001','sewa_selesai_tepat_waktu',10,30,40,'Sewa kedua selesai tepat waktu',NOW() - INTERVAL 120 DAY),
('usr-001-0000-0000-000000000001','riwayat_3x_bersih',30,40,70,'3 transaksi berturut tanpa pelanggaran',NOW() - INTERVAL 80 DAY),
('usr-001-0000-0000-000000000001','referral_pengguna',12,70,82,'Referral 2 pengguna baru',NOW() - INTERVAL 30 DAY),
('usr-025-0000-0000-000000000025','verifikasi_identitas',20,0,20,'NIK dan SIM C terverifikasi',NOW() - INTERVAL 175 DAY),
('usr-025-0000-0000-000000000025','sewa_selesai_tepat_waktu',10,20,30,'Sewa pertama selesai tepat waktu',NOW() - INTERVAL 150 DAY),
('usr-025-0000-0000-000000000025','sewa_selesai_tepat_waktu',10,30,40,'Sewa kedua selesai tepat waktu',NOW() - INTERVAL 120 DAY),
('usr-025-0000-0000-000000000025','riwayat_3x_bersih',30,40,70,'3 transaksi berturut tanpa pelanggaran',NOW() - INTERVAL 80 DAY),
('usr-025-0000-0000-000000000025','referral_pengguna',10,70,80,'Referral 1 pengguna baru',NOW() - INTERVAL 30 DAY),
('usr-027-0000-0000-000000000027','verifikasi_identitas',20,0,20,'NIK dan SIM C terverifikasi',NOW() - INTERVAL 175 DAY),
('usr-027-0000-0000-000000000027','sewa_selesai_tepat_waktu',10,20,30,'Sewa pertama selesai tepat waktu',NOW() - INTERVAL 150 DAY),
('usr-027-0000-0000-000000000027','sewa_selesai_tepat_waktu',10,30,40,'Sewa kedua selesai tepat waktu',NOW() - INTERVAL 120 DAY),
('usr-027-0000-0000-000000000027','riwayat_3x_bersih',30,40,70,'3 transaksi berturut tanpa pelanggaran',NOW() - INTERVAL 80 DAY),
('usr-027-0000-0000-000000000027','referral_pengguna',14,70,84,'Referral 2 pengguna baru',NOW() - INTERVAL 30 DAY);

-- ============================================================
-- END BI DEMO DATA
-- ============================================================

-- ============================================================
-- L3: Recompute biaya_sewa ke model harga harian (tarif_per_hari)
-- ============================================================
UPDATE payments p
JOIN bookings b ON p.booking_id = b.booking_id
JOIN vehicles v ON b.vehicle_id = v.vehicle_id
SET
  p.biaya_sewa      = CEIL(b.durasi_jam / 24) * COALESCE(v.tarif_per_hari, 70000),
  p.deposit_virtual = GREATEST(150000, CEIL(b.durasi_jam / 24) * COALESCE(v.tarif_per_hari, 70000) * 0.5),
  p.total_bayar     = CEIL(b.durasi_jam / 24) * COALESCE(v.tarif_per_hari, 70000)
                    + COALESCE(p.pickup_fee, 0)
                    + COALESCE(b.delivery_fee, 0)
                    + GREATEST(150000, CEIL(b.durasi_jam / 24) * COALESCE(v.tarif_per_hari, 70000) * 0.5)
WHERE b.status_booking IN ('completed', 'active');

-- ============================================================
-- L2: Set vendor saldo dari total kredit booking yang sudah selesai
-- ============================================================
UPDATE vendors vn
JOIN (
  SELECT v.vendor_id,
    SUM(
      p.biaya_sewa * (1 - COALESCE(vs.komisi_platform, 7) / 100.0)
      + COALESCE(p.pickup_fee, 0)
      + COALESCE(b.delivery_fee, 0)
    ) AS total_credit
  FROM payments p
  JOIN bookings b ON p.booking_id = b.booking_id
  JOIN vehicles v ON b.vehicle_id = v.vehicle_id
  JOIN vendors vnd ON v.vendor_id = vnd.vendor_id
  LEFT JOIN vendor_subscriptions vs ON vnd.subscription_id = vs.subscription_id
  WHERE p.status_payment IN ('captured', 'partially_refunded')
  GROUP BY v.vendor_id
) calc ON vn.vendor_id = calc.vendor_id
SET vn.saldo = calc.total_credit;

-- ============================================================
-- Sync users.saldo_ewallet dari ewallet_accounts (mirror invariant)
-- ============================================================
UPDATE users u
JOIN (
  SELECT user_id, COALESCE(SUM(saldo), 0) AS total_saldo
  FROM ewallet_accounts
  GROUP BY user_id
) ea ON u.user_id = ea.user_id
SET u.saldo_ewallet = ea.total_saldo;
