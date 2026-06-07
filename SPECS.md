# Spesifikasi Sistem RentHub

Dokumen ini adalah satu-satunya sumber kebenaran (single source of truth) untuk sistem RentHub. Isinya menjelaskan tujuan, ruang lingkup, arsitektur, model data, aturan bisnis, formula perhitungan, antarmuka pemrograman (API), serta batasan sistem secara menyeluruh. Dokumen disusun berdasarkan analisis langsung terhadap kode sumber pada `backend/src`, `database/schema.sql`, `database/seed.sql`, dan `frontend/lib`, bukan berdasarkan asumsi.

| Atribut | Nilai |
|---------|-------|
| Nama produk | RentHub |
| Kelompok | Kelompok 1 |
| Perusahaan | PT. RenthubIndo |
| Jenis | Prototipe (proof of concept) marketplace sewa motor |
| Konteks | Proyek sprint mata kuliah Pengembangan Perangkat Lunak, Universitas Gadjah Mada, 2026 |
| Status integrasi eksternal | Seluruhnya disimulasikan (Dukcapil, Korlantas, payment gateway, IoT/GPS) |
| Versi dokumen | 1.0 |

### Tim Pengembang (Kelompok 1)

| Nama | Jabatan |
|------|---------|
| Gilbert Fandiliam Mooy | Chief Executive Officer (CEO) |
| Alfi Maulana Akbar | Chief Technology Officer (CTO) |
| Engelbertus Rande | Chief Product Officer (CPO) |
| Zildan Alfatif Agustian | Chief Operating Officer (COO) |

---

## Daftar Isi

1. [Ringkasan Eksekutif](#1-ringkasan-eksekutif)
2. [Tujuan dan Ruang Lingkup](#2-tujuan-dan-ruang-lingkup)
3. [Aktor dan Peran](#3-aktor-dan-peran)
4. [Arsitektur Sistem](#4-arsitektur-sistem)
5. [Teknologi dan Dependensi](#5-teknologi-dan-dependensi)
6. [Model Data dan Skema Database](#6-model-data-dan-skema-database)
7. [Modul Fungsional dan Aturan Bisnis](#7-modul-fungsional-dan-aturan-bisnis)
8. [Formula dan Konstanta Bisnis](#8-formula-dan-konstanta-bisnis)
9. [Spesifikasi API](#9-spesifikasi-api)
10. [Komunikasi Real-time](#10-komunikasi-real-time)
11. [Keamanan](#11-keamanan)
12. [Simulasi Layanan Eksternal](#12-simulasi-layanan-eksternal)
13. [Data Demo dan Seed](#13-data-demo-dan-seed)
14. [Batasan, Asumsi, dan Catatan Diskrepansi](#14-batasan-asumsi-dan-catatan-diskrepansi)

---

## 1. Ringkasan Eksekutif

RentHub adalah platform yang mempertemukan penyewa sepeda motor dengan banyak vendor rental dalam satu aplikasi. Penyewa dapat mendaftar, memverifikasi identitas secara otomatis, mengisi dompet digital, memesan motor, membuka kunci motor melalui aplikasi, dan mengembalikannya dengan perhitungan biaya yang transparan. Vendor dapat mengelola armada, memantau pendapatan, mengontrol kunci motor dari jarak jauh, dan mengelola langganan platform.

Nilai pembeda utama sistem ini ada pada empat pilar:

1. **Kepercayaan terukur (trust score).** Setiap penyewa memiliki skor 0 sampai 100 yang naik turun berdasarkan perilaku sewa, dengan empat tingkatan keanggotaan.
2. **Pembayaran aman berbasis pra-otorisasi.** Dana sewa dan deposit ditahan saat pemesanan dan dilepas atau dikembalikan saat pengembalian, dengan buku besar audit per transaksi.
3. **Kunci pintar bersyarat (No Funds, No Key).** Motor hanya dapat dibuka jika pembayaran telah tervalidasi dan token kunci cocok.
4. **Akuntabilitas lokasi (geofence).** Pengembalian divalidasi terhadap titik kembali yang ditentukan; pelanggaran menurunkan trust score.

Karena berstatus prototipe akademik, seluruh layanan pihak ketiga digantikan oleh tabel dan logika simulasi di dalam sistem, sehingga aplikasi dapat berjalan utuh secara offline tanpa biaya integrasi.

---

## 2. Tujuan dan Ruang Lingkup

### 2.1 Tujuan

- Mendemonstrasikan siklus penuh penyewaan motor dari verifikasi identitas hingga penyelesaian pembayaran.
- Menunjukkan integrasi backend transaksional (MySQL dengan kunci baris dan transaksi atomik) dengan frontend mobile.
- Menampilkan fitur real-time (pelacakan lokasi dan notifikasi) melalui WebSocket.

### 2.2 Termasuk dalam Ruang Lingkup

- Manajemen akun dan autentikasi penyewa serta vendor.
- Verifikasi identitas (NIK dan SIM) berbasis data simulasi.
- Katalog kendaraan, estimasi biaya, pemesanan, pembayaran, pengembalian, dan pembatalan.
- Dompet digital multi metode dengan top up, potong, dan refund.
- Kontrol IoT (buka/kunci) dan telemetri lokasi.
- Geofence dan denda keterlambatan.
- Dashboard vendor, manajemen armada, langganan, dan komisi.
- Ulasan, rating, dan notifikasi.

### 2.3 Di Luar Ruang Lingkup

- Integrasi nyata dengan Dukcapil, Korlantas, payment gateway, atau perangkat IoT fisik.
- Penyewaan jenis kendaraan selain sepeda motor (skema menetapkan `jenis` hanya bernilai `motor`).
- Proses penarikan saldo vendor (withdrawal) ke rekening bank nyata.
- Panel administrator platform (tidak ada peran admin di kode).

---

## 3. Aktor dan Peran

| Aktor | Deskripsi | Cara autentikasi |
|-------|-----------|------------------|
| Penyewa (user) | Pengguna yang mencari, memesan, dan mengembalikan motor. | JWT dengan `role: user` |
| Vendor | Pemilik rental yang menyediakan armada dan mengelola operasional. | JWT dengan `role: vendor` |
| Sistem (worker) | Proses latar yang mensimulasikan telemetri GPS dan auto-suspend. | Internal, tanpa token |
| Layanan eksternal tersimulasi | Dukcapil, Korlantas, payment gateway. | Tidak ada, diakses sebagai tabel/logika internal |

Tidak terdapat peran administrator pada implementasi saat ini.

---

## 4. Arsitektur Sistem

### 4.1 Gambaran Umum

```
+----------------------+        HTTP REST (JSON)        +-------------------------+
|   Flutter Frontend   | <----------------------------> |   Express Backend API   |
|  (Provider state)    |        WebSocket (Socket.IO)   |   (Node.js)             |
+----------------------+ <----------------------------> +-------------------------+
                                                              |          |
                                                       mysql2 pool   Socket.IO + worker
                                                              |          |
                                                        +-----------+    |
                                                        |  MySQL 8  |<---+
                                                        +-----------+
                                                  (tabel simulasi Dukcapil,
                                                   Korlantas, e-wallet)
```

### 4.2 Backend

Backend adalah satu aplikasi Express (`backend/src/app.js`) yang:

- Memasang 12 modul route di bawah prefix `/api`.
- Menginisialisasi server HTTP dan Socket.IO pada port yang sama.
- Menyimpan instance Socket.IO di `app.set('io', io)` agar dapat diakses dari handler route untuk emisi event.
- Menjalankan worker telemetry saat startup (kecuali mode test).
- Menyediakan endpoint health check `GET /api/health`.
- Memuat variabel lingkungan dari `.env` (atau `.env.test` saat `NODE_ENV=test`).

Koneksi database memakai pool `mysql2/promise` (`backend/config/database.js`) dengan `connectionLimit: 20` dan `timezone: '+07:00'`. Tersedia helper `query(sql, params)` untuk kueri sederhana, sedangkan transaksi memakai `pool.getConnection()` langsung.

Modul route:

| Modul | Prefix | Tanggung jawab |
|-------|--------|----------------|
| `auth.routes.js` | `/api/auth` | Registrasi, login penyewa dan vendor, refresh token, logout, verifikasi identitas |
| `user.routes.js` | `/api/users` | Profil penyewa, ubah profil, riwayat trust |
| `vehicle.routes.js` | `/api/vehicles` | Katalog publik kendaraan dan detail |
| `booking.routes.js` | `/api/bookings` | Estimasi, pembuatan booking atomik, riwayat, audit, pengembalian, pembatalan |
| `payment.routes.js` | `/api/payments` | Pencarian pembayaran (read-only) |
| `geofence.routes.js` | `/api/geofences` | Daftar geofence dan validasi titik |
| `iot.routes.js` | `/api/iot` | Buka/kunci oleh penyewa, kontrol kunci oleh vendor, status IoT |
| `vendor.routes.js` | `/api/vendors` | Dashboard, armada, booking vendor, profil, denda, waive |
| `mock.routes.js` | `/api/mock` | Endpoint simulasi Dukcapil, Korlantas, pra-otorisasi |
| `notification.routes.js` | `/api/notifications` | Notifikasi penyewa dan vendor |
| `review.routes.js` | `/api/reviews` | Kirim ulasan, daftar ulasan, status ulasan booking |
| `ewallet.routes.js` | `/api/ewallet` | Top up dan riwayat transaksi dompet |

Utilitas pendukung:

- `utils/trust.js` - fungsi `levelFromScore(score)` memetakan skor ke level keanggotaan.
- `utils/verify.js` - `verifyNik` dan `verifySim` memvalidasi identitas terhadap tabel simulasi.
- `utils/wallet.js` - `deduct` dan `credit` memindahkan saldo dompet secara atomik sekaligus menulis buku besar `ewallet_transactions`.
- `workers/telemetry.worker.js` - setiap 10 detik memperbarui lokasi kendaraan pada booking aktif dan memancarkan event.

### 4.3 Frontend

Aplikasi Flutter dengan manajemen state Provider. Titik masuk `main.dart` membungkus aplikasi dengan `AuthProvider` dan menampilkan `SplashScreen`.

- `services/api_service.dart` - klien HTTP statis yang menambahkan header otorisasi dan menangani refresh token otomatis saat menerima 401 (mencoba refresh lalu mengulang permintaan satu kali).
- `services/auth_provider.dart` - menyimpan sesi penyewa atau vendor, menyimpan token di `flutter_secure_storage`, memulihkan sesi saat aplikasi dibuka, dan mengelola koneksi socket.
- `services/socket_service.dart` - singleton pembungkus Socket.IO untuk koneksi, langganan event, dan pemutusan.
- `utils/constants.dart` - mendefinisikan `baseUrl` dan `socketUrl`. Ini satu-satunya berkas yang perlu diubah saat berpindah platform.

Layar dipisah berdasarkan peran: berkas dengan prefiks `vendor_` untuk antarmuka vendor, sisanya untuk penyewa.

---

## 5. Teknologi dan Dependensi

### 5.1 Backend (`backend/package.json`)

Dependensi runtime: `express`, `socket.io`, `mysql2`, `jsonwebtoken`, `bcrypt`, `cors`, `dotenv`, `uuid`.
Dependensi pengembangan: `jest`, `supertest`, `nodemon`, `cross-env`.

Skrip:

- `npm start` - menjalankan `node src/app.js`.
- `npm run dev` - menjalankan `nodemon src/app.js` (hot reload).
- `npm test` - menjalankan Jest dengan `NODE_ENV=test` secara serial (`--runInBand`).
- `npm run test:coverage` - Jest dengan laporan coverage.

### 5.2 Frontend (`frontend/pubspec.yaml`)

`http`, `provider`, `flutter_secure_storage`, `socket_io_client`, `google_fonts`, `intl`, `flutter_map`, `latlong2`. SDK Dart `>=3.0.0 <4.0.0`.

### 5.3 Database

MySQL 8, mesin penyimpanan InnoDB. Pada pengembangan dijalankan melalui Laragon dan diadministrasi via phpMyAdmin. Tidak ada migration runner; skema dan seed diterapkan manual melalui file SQL.

---

## 6. Model Data dan Skema Database

Database terdiri atas 19 tabel dan 2 view. Seluruh primary key bertipe `VARCHAR(36)` dengan nilai bawaan `UUID()`, kecuali tabel simulasi yang memakai nomor identitas sebagai kunci.

### 6.1 Kelompok Tabel Simulasi Eksternal

**`dukcapil_datadiri`** - data kependudukan simulasi.

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `nik` | VARCHAR(16) PK | Nomor Induk Kependudukan |
| `nama_lengkap` | VARCHAR(150) | Nama sesuai data diri |
| `tanggal_lahir` | DATE | Tanggal lahir |

**`korlantas_sim`** - data SIM simulasi.

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `nomor_sim` | VARCHAR(30) PK | Nomor SIM |
| `nama_lengkap` | VARCHAR(150) | Pemilik SIM |
| `jenis_sim` | ENUM(A, BI, BII, C, D) | Hanya jenis C yang diterima untuk motor |
| `tanggal_berlaku` | DATE | Masa berlaku |
| `status_aktif` | TINYINT(1) | Aktif atau tidak |

**`korlantas_kendaraan`** - data registrasi kendaraan simulasi (untuk verifikasi STNK armada vendor).

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `nomor_plat` | VARCHAR(15) PK | Plat nomor |
| `nomor_stnk` | VARCHAR(50) UNIQUE | Nomor STNK |
| `tanggal_berlaku_stnk` | DATE | Masa berlaku STNK |
| `bukti_pajak_url` | VARCHAR(500) | Opsional |
| `status_aktif` | TINYINT(1) | Aktif atau tidak |

### 6.2 Kelompok Tabel Inti

**`vendor_subscriptions`** - paket langganan platform (tabel referensi).

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `subscription_id` | VARCHAR(36) PK | |
| `kategori` | ENUM(starter, profesional, enterprise) UNIQUE | |
| `harga_per_bulan` | DECIMAL(10,2) | |
| `maks_armada` | INT NULL | NULL berarti tanpa batas |
| `komisi_platform` | DECIMAL(5,2) | Persentase komisi platform |

**`vendors`** - akun dan profil vendor.

Kolom penting: `nama_vendor`, `alamat`, `kota`, `kontak_email` (UNIQUE), `password_hash`, `subscription_id` (FK), `status_langganan` (ENUM active/suspended), `tanggal_jatuh_tempo`, `saldo` (saldo yang dapat ditarik), `biaya_antar`, `rating_avg`, `total_ulasan`, `status_aktif`.

**`users`** - akun dan profil penyewa.

Kolom penting: `nama`, `nama_lengkap`, `email` (UNIQUE), `phone`, `password_hash`, `nik` (UNIQUE, NULL), `nik_hash` (SHA-256), `nomor_sim`, `status_verifikasi` (ENUM pending/verified/rejected), `verifikasi_at`, `trust_score` (0..100 dengan CHECK), `level_trust` (ENUM bronze/silver/gold/platinum), `saldo_ewallet` (cermin total saldo dompet), `foto_profil_url`, `is_active`.

**`ewallet_accounts`** - akun dompet per metode bayar (sumber kebenaran saldo).

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `account_id` | VARCHAR(36) PK | |
| `user_id` | VARCHAR(36) FK | |
| `metode_bayar` | ENUM(gopay, ovo, dana, debit, bca_va, mandiri_va) | |
| `saldo` | DECIMAL(12,2) | Saldo riil per metode |

Constraint unik `(user_id, metode_bayar)` memastikan satu akun per metode per pengguna.

**`ewallet_transactions`** - buku besar audit seluruh pergerakan saldo.

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `txn_id` | VARCHAR(36) PK | |
| `account_id` | VARCHAR(36) FK | |
| `tipe` | ENUM(topup, deduct, refund, transfer_out, transfer_in) | |
| `amount` | DECIMAL(12,2) | Nominal pergerakan |
| `saldo_sebelum`, `saldo_sesudah` | DECIMAL(12,2) | Snapshot saldo |
| `ref_booking_id` | VARCHAR(36) NULL | Kaitan ke booking bila relevan |
| `keterangan` | VARCHAR(200) | |

**`vehicles`** - armada motor.

Kolom penting: `vendor_id` (FK), `jenis` (ENUM hanya `motor`), `merek`, `model`, `tahun`, `plat_nomor` (UNIQUE), `nomor_stnk`, `warna`, `status` (ENUM available/rented/maintenance/inactive), `tarif_per_jam`, `tarif_deposit`, `kapasitas`, `foto_url`, `deskripsi`, `fitur` (JSON), `lokasi_lat`/`lokasi_lng` (default area Yogyakarta), `iot_device_id`, `rating_avg`, `total_ulasan`, `tarif_per_hari` (NULL diperbolehkan).

**`geofences`** - zona lokasi untuk titik kembali dan biaya jemput.

Kolom penting: `vendor_id` (FK, NULL untuk lokasi publik), `nama_lokasi`, `latitude`, `longitude`, `radius_meter` (default 100), `tipe` (ENUM vendor_garage/station/airport/mall/campus/custom), `pickup_fee`, `is_active`.

**`bookings`** - catatan sentral penyewaan.

Kolom penting: `user_id`, `vehicle_id`, `geofence_id` (FK, NULL), `waktu_mulai`, `waktu_selesai`, `waktu_aktual_kembali`, `durasi_jam`, `status_booking` (ENUM pending/confirmed/active/completed/cancelled), `pickup_fee`, `unlock_token`, `geofence_validated`, `catatan`, `delivery_fee`, `metode_pengambilan` (ENUM ambil_sendiri/diantar).

**`payments`** - satu pembayaran per booking (relasi 1:1, `booking_id` UNIQUE).

Kolom penting: `biaya_sewa`, `deposit_virtual`, `pickup_fee`, `total_bayar`, `metode_bayar`, `status_payment` (ENUM pending/pre_authorized/captured/refunded/failed/partially_refunded), `gateway_ref`, `pre_auth_ref`, `deposit_dilepas_at`, `refund_amount`, `paid_at`.

**`penalties`** - denda keterlambatan per booking.

Kolom penting: `durasi_overtime_menit`, `tarif_per_jam_denda`, `nominal_denda`, `status_potong` (ENUM pending/deducted/waived), `auto_deduct_at`, `keterangan`.

**`reviews`** - ulasan, satu per booking (`booking_id` UNIQUE).

Kolom penting: `user_id`, `vehicle_id`, `rating` (1..5 dengan CHECK), `komentar`.

**`iot_logs`** - jejak telemetri kendaraan.

Kolom penting: `vehicle_id`, `booking_id` (NULL), `lokasi_lat`/`lokasi_lng`, `status_mesin` (on/off/idle), `status_kunci` (locked/unlocked), `kecepatan`, `raw_data` (JSON), `waktu_update`.

**`trust_logs`** - jejak audit perubahan trust score.

Kolom penting: `user_id`, `booking_id` (NULL), `parameter`, `delta_skor`, `skor_sebelum`, `skor_sesudah`, `keterangan`.

**`unlock_logs`** - jejak aksi kunci.

Kolom penting: `vehicle_id`, `user_id` (NULL), `booking_id` (NULL), `aksi` (ENUM unlock/lock/force_lock/emergency_lock), `sumber` (ENUM mobile_app/vendor_dashboard/system_auto/api_gateway), `berhasil`, `keterangan`, `waktu_aksi`.

**`notifications`** - notifikasi untuk penyewa atau vendor.

Kolom penting: `user_id` (NULL), `vendor_id` (NULL), `tipe`, `judul`, `pesan`, `data_json` (JSON), `is_read`.

**`refresh_tokens`** - rotasi refresh token berbasis JTI.

Kolom penting: `user_id` (NULL), `vendor_id` (NULL), `jti` (UNIQUE), `expires_at`, `revoked`.

### 6.3 View

**`v_booking_detail`** - join lengkap booking dengan penyewa, kendaraan, vendor, pembayaran, dan geofence. Dipakai mayoritas endpoint booking. Menyertakan kolom turunan `durasi_hari = ROUND(durasi_jam / 24)` dan `nama_kendaraan = CONCAT(merek, model, tahun)`.

**`v_vendor_dashboard`** - agregat statistik per vendor. Beberapa kolom kunci:

- `saldo_akun` - saldo `vendors.saldo` yang dapat ditarik.
- `total_armada`, `unit_tersedia`, `unit_disewa`, `unit_maintenance` - hitungan unit per status.
- `pendapatan_kotor` - jumlah `biaya_sewa + pickup_fee + delivery_fee` untuk pembayaran berstatus `captured` atau `partially_refunded`.
- `pendapatan_hari_ini` dan `pendapatan_bulan_ini` - varian pendapatan kotor terbatas tanggal.
- `pendapatan_total` - pendapatan bersih setelah komisi: `biaya_sewa * (1 - komisi/100) + pickup_fee + delivery_fee`. Bersifat pelaporan, bukan saldo.

### 6.4 Relasi Inti

```
vendor_subscriptions 1---* vendors 1---* vehicles 1---* bookings 1---1 payments
                                  |                   |            
                                  |                   *---1 geofences
users 1---* bookings              |                   *---* iot_logs / unlock_logs / penalties
users 1---* ewallet_accounts 1---* ewallet_transactions
users 1---* trust_logs
bookings 1---1 reviews
```

---

## 7. Modul Fungsional dan Aturan Bisnis

### 7.1 Registrasi dan Verifikasi Identitas

Registrasi (`POST /api/auth/register`) bersifat satu langkah dengan verifikasi inline:

1. Validasi field wajib (`nama`, `email`, `password`, `nik`, `nomor_sim`).
2. Email harus unik.
3. NIK diverifikasi ke `dukcapil_datadiri` melalui `verifyNik`. Gagal bila format bukan 16 digit atau tidak ditemukan.
4. SIM diverifikasi ke `korlantas_sim` melalui `verifySim`. Gagal bila tidak ditemukan, tidak aktif, atau bukan jenis C.
5. Bila keduanya valid, akun dibuat langsung berstatus `verified`, trust score awal `TRUST_SCORE_VERIFY` (20), level mengikuti skor.
6. Dalam satu transaksi, sistem juga membuat tiga akun dompet default (gopay, ovo, dana) bersaldo 0 dan menulis `trust_logs` parameter `verifikasi_identitas`.

Verifikasi terpisah (`POST /api/auth/verify-identity`) tersedia untuk akun yang belum terverifikasi. Logikanya menambah trust hanya jika `status_verifikasi` belum `verified`, sehingga verifikasi ulang tidak menambah poin berganda. Kegagalan menulis `trust_logs` parameter `verification_failed` dengan delta 0.

### 7.2 Autentikasi dan Sesi

- Login penyewa (`/api/auth/login`) dan vendor (`/api/auth/login-vendor`) memvalidasi kredensial dengan `bcrypt.compare`.
- Pada mode development, terdapat fallback demo: bila hash lama tidak cocok namun password termasuk daftar demo (`user@123`, `demo1234`, atau `vendor@123`), sistem melakukan re-hash dan meloloskan login. Fallback ini hanya aktif saat `NODE_ENV=development`.
- Setiap login menerbitkan pasangan token: access token (kedaluwarsa `JWT_EXPIRES_IN`, bawaan 15 menit) dan refresh token (kedaluwarsa 30 hari) yang dicatat di `refresh_tokens` dengan JTI unik.
- Refresh (`/api/auth/refresh`) memvalidasi JTI yang belum dicabut dan belum kedaluwarsa, mencabut token lama (rotasi), lalu menerbitkan pasangan baru.
- Logout (`/api/auth/logout`) mencabut refresh token berdasarkan JTI.

### 7.3 Trust Score dan Level

Trust score adalah bilangan bulat 0 sampai 100. Perubahan dipicu oleh peristiwa berikut dan selalu dicatat di `trust_logs`:

| Peristiwa | Parameter env | Nilai bawaan |
|-----------|---------------|--------------|
| Verifikasi identitas | `TRUST_SCORE_VERIFY` | +20 |
| Pengembalian tepat waktu | `TRUST_SCORE_TEPAT_WAKTU` | +10 |
| Keterlambatan ringan (<= 60 menit) | `TRUST_SCORE_OVERTIME_RINGAN` | -10 |
| Keterlambatan berat (> 60 menit) | `TRUST_SCORE_OVERTIME_BERAT` | -20 |
| Gagal bayar (saldo kurang saat booking) | `TRUST_SCORE_GAGAL_BAYAR` | -5 |
| Pelanggaran geofence saat kembali | `TRUST_SCORE_GEOFENCE_BREACH` | -15 |

Skor dijaga dalam rentang 0..100 (`Math.max(0, Math.min(100, ...))`). Level dipetakan oleh `levelFromScore`:

| Rentang skor | Level |
|--------------|-------|
| 90 - 100 | platinum |
| 75 - 89 | gold |
| 50 - 74 | silver |
| 0 - 49 | bronze |

### 7.4 Katalog Kendaraan

- `GET /api/vehicles` menampilkan kendaraan beserta info vendor. Tanpa filter status, kendaraan `inactive` dikecualikan. Hasil diurutkan: tersedia lebih dulu, lalu rating tertinggi.
- `GET /api/vehicles/:id` menambahkan status IoT terakhir dari `iot_logs`.
- Kolom `fitur` disimpan sebagai JSON dan diparse menjadi array sebelum dikirim.

### 7.5 Estimasi Biaya

`POST /api/bookings/estimate` menghitung rincian biaya tanpa membuat transaksi. Formula identik dengan pembuatan booking (lihat Bagian 8). Mendukung penghitungan berbasis `durasi_jam` atau `durasi_hari`.

### 7.6 Siklus Hidup Booking

Pembuatan booking (`POST /api/bookings`) berjalan dalam satu transaksi atomik dengan kunci baris:

1. Kunci baris kendaraan (`FOR UPDATE`). Gagal bila status bukan `available` (HTTP 409).
2. Cek auto-suspend vendor. Bila suspended, tolak (HTTP 403).
3. Kunci baris pengguna. Gagal bila belum `verified` (HTTP 403).
4. Hitung biaya: biaya sewa, pickup fee, delivery fee, dan deposit virtual.
5. Kunci baris akun dompet pada metode bayar terpilih. Bila metode tidak terdaftar, tolak (HTTP 400).
6. Bila saldo kurang: kurangi trust score sebesar `TRUST_SCORE_GAGAL_BAYAR`, catat `trust_logs`, commit, lalu kembalikan HTTP 402 dengan kode `INSUFFICIENT_FUNDS`.
7. Bila cukup: buat booking berstatus `active` dengan `unlock_token` unik, buat pembayaran berstatus `pre_authorized`, potong saldo penuh dari dompet (via `deduct`), ubah status kendaraan menjadi `rented`, tulis log IoT awal (terkunci), kirim notifikasi vendor, dan catat `trust_logs` parameter `booking_created` (delta 0).
8. Setelah commit, pancarkan event `booking:new` ke room vendor.

Catatan penting: booking langsung berstatus `active` setelah pembayaran berhasil. Tidak ada langkah konfirmasi terpisah pada implementasi ini, meskipun enum status menyediakan `pending` dan `confirmed`.

Endpoint terkait:

- `GET /api/bookings/my` - 20 booking terakhir milik penyewa (dari `v_booking_detail`).
- `GET /api/bookings/:id` - detail satu booking.
- `GET /api/bookings/:id/audit` - jejak audit lengkap (trust, unlock, IoT, denda, pembayaran). Hanya pemilik booking.

### 7.7 Buka dan Kunci Kendaraan (IoT)

Buka oleh penyewa (`POST /api/iot/unlock`):

1. Booking harus milik pemohon dan berstatus `active`.
2. Status pembayaran harus `pre_authorized` atau `captured`. Bila tidak, catat upaya gagal di `unlock_logs` dan kembalikan HTTP 402 kode `NO_FUNDS_NO_KEY`. Inilah prinsip "No Funds, No Key".
3. Untuk aksi `unlock`, `unlock_token` wajib dikirim dan cocok dengan token booking. Bila tidak, catat kegagalan dan kembalikan HTTP 403 kode `INVALID_TOKEN`.
4. Bila lolos, tulis `iot_logs` (mesin on/off, kunci unlocked/locked), tulis `unlock_logs` sukses, perbarui lokasi kendaraan (acak di sekitar Yogyakarta saat unlock), dan pancarkan `vehicle:update` ke room vendor.

Kontrol oleh vendor (`POST /api/iot/vendor/lock`) mengizinkan aksi `force_lock`, `emergency_lock`, atau `unlock` atas kendaraan milik vendor sendiri, mencatat log, dan memancarkan `vehicle:update` ke vendor serta penyewa booking aktif (bila ada).

Status IoT (`GET /api/iot/status/:vehicle_id`) mengembalikan kondisi terakhir; bila mesin menyala, kecepatan dan posisi sedikit diacak untuk meniru pergerakan.

### 7.8 Pengembalian Kendaraan

`POST /api/bookings/:id/return` berjalan atomik:

1. Kunci baris booking (harus milik penyewa dan berstatus `active`).
2. Hitung jarak ke geofence titik kembali memakai pendekatan Haversine sederhana. Valid bila jarak <= `radius_meter` (bawaan 100). Bila koordinat tidak dikirim, dianggap valid.
3. Hitung keterlambatan (overtime) dalam menit dari `waktu_selesai`.
4. Bila terlambat, hitung denda (lihat Bagian 8), potong dari deposit, catat `penalties` berstatus `deducted`, dan tetapkan delta trust ringan atau berat.
5. Bila tepat waktu, tetapkan delta trust positif.
6. Perbarui booking menjadi `completed`, catat `waktu_aktual_kembali` dan hasil validasi geofence.
7. Perbarui pembayaran: `captured` bila tepat waktu, `partially_refunded` bila ada denda; catat `deposit_dilepas_at`.
8. Ubah status kendaraan menjadi `available`.
9. Kreditkan pendapatan ke saldo vendor (lihat Bagian 8).
10. Terapkan delta trust waktu, lalu delta geofence (-15) terpisah bila melanggar; keduanya dicatat di `trust_logs`.
11. Kembalikan sisa deposit ke metode bayar asal via `credit`.
12. Kirim notifikasi vendor dan pancarkan `booking:returned`.

### 7.9 Pembatalan Booking

`POST /api/bookings/:id/cancel` hanya boleh untuk booking `active` yang belum pernah dibuka. Bila ada catatan `unlock` di `unlock_logs`, pembatalan ditolak (HTTP 409). Bila lolos, seluruh `total_bayar` dikembalikan ke metode asal, booking menjadi `cancelled`, pembayaran menjadi `refunded`, kendaraan kembali `available`, dan vendor diberi notifikasi serta event `booking:cancelled`.

### 7.10 Dompet Digital

- Saldo riil disimpan per metode di `ewallet_accounts`. Kolom `users.saldo_ewallet` adalah cermin total yang disinkronkan setiap kali `deduct` atau `credit` dipanggil.
- Setiap pergerakan saldo menulis baris `ewallet_transactions` dengan snapshot saldo sebelum dan sesudah, menjadikannya buku besar audit.
- Top up (`POST /api/ewallet/topup`) menambah saldo metode tertentu dan tercatat sebagai tipe `topup`.
- Riwayat (`GET /api/ewallet/transactions`) dapat difilter per metode.

### 7.11 Pembayaran (read-only)

`GET /api/payments/:booking_id` hanya membaca data pembayaran milik penyewa. Operasi capture, refund, dan deduct tidak ditangani di sini, melainkan di alur booking melalui `wallet.js`.

### 7.12 Manajemen Vendor dan Armada

- Dashboard (`GET /api/vendors/dashboard`) membaca `v_vendor_dashboard`.
- Daftar armada (`GET /api/vendors/fleet`) menyertakan status IoT terakhir tiap unit.
- Tambah armada (`POST /api/vendors/fleet`):
  1. Tolak bila vendor suspended.
  2. Tegakkan batas armada langganan: bila `maks_armada` tidak NULL dan jumlah unit non-inactive sudah mencapai batas, tolak (HTTP 409).
  3. Verifikasi plat ke `korlantas_kendaraan`. Bila tidak ditemukan atau tidak aktif, kendaraan tetap dibuat namun berstatus `inactive` dan `verified=false`. Bila STNK kedaluwarsa, juga `inactive`. Bila valid, status `available` dan `verified=true`.
  4. Bila `tarif_per_jam` tidak diisi, dihitung dari `tarif_per_hari / 24`. Deposit bawaan `max(150000, tarif_per_hari * 0.5)`.
- Ubah armada (`PUT /api/vendors/fleet/:vehicle_id`) membatasi field yang boleh diubah dan memvalidasi status hanya ke available/maintenance/inactive.
- Hapus armada (`DELETE /api/vendors/fleet/:vehicle_id`) bersifat soft delete (status menjadi `inactive`). Unit yang sedang `rented` tidak dapat dihapus.
- Ubah profil (`PUT /api/vendors/profile`) mengizinkan `biaya_antar`, `kontak_phone`, `alamat`, `kota`.

### 7.13 Langganan dan Auto-Suspend

Tiga paket langganan (nilai dari seed):

| Kategori | Harga per bulan | Maks armada | Komisi platform |
|----------|-----------------|-------------|-----------------|
| starter | Rp 299.000 | 5 | 7% |
| profesional | Rp 599.000 | 20 | 6% |
| enterprise | Rp 999.000 | tanpa batas | 5% |

Fungsi `checkAndAutoSuspend(vendorId)` menetapkan vendor menjadi `suspended` bila berstatus `active` namun melewati `tanggal_jatuh_tempo` ditambah masa tenggang 3 hari. Pengecekan ini dipanggil saat pembuatan booking dan penambahan armada.

### 7.14 Denda dan Pembebasan

- Denda keterlambatan dibuat saat pengembalian (Bagian 7.8 dan 8).
- Vendor dapat melihat denda booking miliknya (`GET /api/vendors/bookings/:booking_id/penalties`).
- Vendor dapat membebaskan denda (`POST /api/vendors/penalties/:penalty_id/waive`) yang masih berstatus `deducted`. Nominal denda dikembalikan ke metode bayar penyewa, status denda menjadi `waived`, `refund_amount` pembayaran ditambah, dan penyewa diberi notifikasi.

### 7.15 Ulasan dan Rating

- Ulasan (`POST /api/reviews`) hanya untuk booking `completed` milik penyewa, satu ulasan per booking, rating 1..5.
- Setiap ulasan baru memicu pembaruan `rating_avg` dan `total_ulasan` pada kendaraan, lalu agregasi rating ke vendor pemilik (rata-rata seluruh ulasan armadanya).
- Ulasan kendaraan (`GET /api/reviews/vehicle/:id`) bersifat publik. Status ulasan booking (`GET /api/reviews/booking/:id`) untuk pemilik.

### 7.16 Notifikasi

Notifikasi disimpan di tabel `notifications` dan dibuat sebagai efek samping di handler lain (booking, pengembalian, pembatalan, waive). Penyewa dan vendor memiliki endpoint baca dan tandai-dibaca masing-masing. Emisi real-time terjadi melalui Socket.IO pada peristiwa terkait.

---

## 8. Formula dan Konstanta Bisnis

Seluruh formula di bawah diambil langsung dari `booking.routes.js` dan `vendor.routes.js`.

### 8.1 Biaya Sewa

```
Jika durasi_hari diberikan:
    jam_efektif  = durasi_hari * 24
    biaya_sewa   = tarif_per_hari * durasi_hari
Jika tidak (pakai durasi_jam):
    jam_efektif  = durasi_jam
    biaya_sewa   = tarif_per_jam * durasi_jam
```

`tarif_per_hari` bernilai bawaan 70.000 bila kolom kendaraan kosong (NULL).

### 8.2 Biaya Tambahan dan Total

```
pickup_fee      = geofences.pickup_fee (bila geofence dipilih, selain itu 0)
delivery_fee    = vendors.biaya_antar  (bila metode_pengambilan = diantar, selain itu 0)
deposit_virtual = max(150000, biaya_sewa * 0.5)
total_bayar     = biaya_sewa + pickup_fee + delivery_fee + deposit_virtual
```

### 8.3 Denda Keterlambatan

```
overtime_menit   = max(0, sekarang - waktu_selesai) dalam menit
tarif_denda_jam  = (tarif_per_hari / 24) * 1.5
jam_terlambat    = ceil(overtime_menit / 60)
nominal_denda    = min(jam_terlambat * tarif_denda_jam, deposit_virtual)
refund_deposit   = deposit_virtual - nominal_denda
```

Denda tidak pernah melebihi deposit. Pengali keterlambatan adalah 1,5 kali tarif per jam yang dihitung dari tarif harian.

### 8.4 Kredit Vendor saat Pengembalian

```
komisi      = vendor_subscriptions.komisi_platform (bawaan 7 bila tidak ada)
vendor_rate = 1 - komisi / 100
vendor_credit = biaya_sewa * vendor_rate + pickup_fee + delivery_fee
```

Kredit ini ditambahkan ke `vendors.saldo`. Deposit tidak termasuk pendapatan vendor karena bersifat jaminan yang dikembalikan.

### 8.5 Konstanta Trust Score

Lihat tabel pada Bagian 7.3. Seluruh nilai dapat dikonfigurasi melalui variabel lingkungan dengan nilai bawaan yang tercantum.

---

## 9. Spesifikasi API

Seluruh endpoint berada di bawah base `/api`. Respons mengikuti pola `{ success: boolean, message?, data?, ... }`. Endpoint yang memerlukan autentikasi mengharapkan header `Authorization: Bearer <access_token>`.

### 9.1 Autentikasi (`/auth`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| POST | `/auth/register` | - | Registrasi penyewa dengan verifikasi inline |
| POST | `/auth/login` | - | Login penyewa |
| POST | `/auth/login-vendor` | - | Login vendor |
| POST | `/auth/refresh` | - | Tukar refresh token dengan pasangan token baru |
| POST | `/auth/logout` | - | Cabut refresh token |
| POST | `/auth/verify-identity` | penyewa | Verifikasi identitas untuk akun belum terverifikasi |

### 9.2 Pengguna (`/users`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/users/profile` | penyewa | Profil beserta saldo dan daftar akun dompet |
| PUT | `/users/profile` | penyewa | Ubah nama, email, phone, foto |
| GET | `/users/trust-history` | penyewa | 20 entri trust terakhir |

### 9.3 Kendaraan (`/vehicles`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/vehicles` | - | Katalog kendaraan, filter `jenis` dan `status` |
| GET | `/vehicles/:id` | - | Detail kendaraan dengan status IoT terakhir |

### 9.4 Booking (`/bookings`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| POST | `/bookings/estimate` | penyewa | Estimasi biaya |
| POST | `/bookings` | penyewa | Buat booking atomik dengan pembayaran |
| GET | `/bookings/my` | penyewa | Riwayat booking penyewa |
| GET | `/bookings/:id` | penyewa | Detail booking |
| GET | `/bookings/:id/audit` | penyewa (pemilik) | Jejak audit lengkap |
| POST | `/bookings/:id/return` | penyewa | Pengembalian dengan validasi geofence dan denda |
| POST | `/bookings/:id/cancel` | penyewa | Pembatalan sebelum kendaraan dibuka |

### 9.5 Pembayaran (`/payments`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/payments/:booking_id` | penyewa (pemilik) | Detail pembayaran |

### 9.6 Geofence (`/geofences`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/geofences` | - | Daftar geofence aktif |
| POST | `/geofences/validate` | - | Validasi titik terhadap radius geofence |

### 9.7 IoT (`/iot`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| POST | `/iot/unlock` | penyewa | Buka atau kunci oleh penyewa |
| POST | `/iot/vendor/lock` | vendor | Kontrol kunci oleh vendor |
| GET | `/iot/status/:vehicle_id` | terautentikasi | Status IoT terakhir |

### 9.8 Vendor (`/vendors`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/vendors/dashboard` | vendor | Statistik agregat |
| GET | `/vendors/fleet` | vendor | Daftar armada |
| POST | `/vendors/fleet` | vendor | Tambah armada (verifikasi STNK, cap langganan) |
| PUT | `/vendors/fleet/:vehicle_id` | vendor | Ubah armada |
| DELETE | `/vendors/fleet/:vehicle_id` | vendor | Nonaktifkan armada (soft delete) |
| GET | `/vendors/bookings` | vendor | Booking vendor, filter `vehicle_id` |
| PUT | `/vendors/profile` | vendor | Ubah profil vendor |
| GET | `/vendors/bookings/:booking_id/penalties` | vendor | Denda untuk booking vendor |
| POST | `/vendors/penalties/:penalty_id/waive` | vendor | Bebaskan denda dan refund |

### 9.9 Notifikasi (`/notifications`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| GET | `/notifications` | penyewa | Notifikasi penyewa |
| PATCH | `/notifications/read-all` | penyewa | Tandai semua dibaca |
| PATCH | `/notifications/:id/read` | penyewa | Tandai satu dibaca |
| GET | `/notifications/vendor` | vendor | Notifikasi vendor |
| PATCH | `/notifications/vendor/:id/read` | vendor | Tandai satu (vendor) dibaca |

### 9.10 Ulasan (`/reviews`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| POST | `/reviews` | penyewa | Kirim ulasan booking selesai |
| GET | `/reviews/vehicle/:id` | - | Daftar ulasan kendaraan |
| GET | `/reviews/booking/:id` | penyewa | Status ulasan booking |

### 9.11 Dompet (`/ewallet`)

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| POST | `/ewallet/topup` | penyewa | Top up saldo metode |
| GET | `/ewallet/transactions` | penyewa | Riwayat transaksi, filter metode |

### 9.12 Simulasi (`/mock`) dan Health

| Metode | Path | Auth | Deskripsi |
|--------|------|------|-----------|
| POST | `/mock/dukcapil/verify` | - | Simulasi verifikasi NIK dengan jeda |
| POST | `/mock/korlantas/verify` | - | Simulasi verifikasi SIM dengan jeda |
| POST | `/mock/payment/pre-auth` | - | Simulasi pra-otorisasi pembayaran |
| GET | `/health` | - | Health check |

### 9.13 Ringkasan Kode Status

| Kode | Makna dalam konteks RentHub |
|------|------------------------------|
| 200 / 201 | Berhasil |
| 400 | Input tidak lengkap atau tidak valid |
| 401 | Token tidak ada atau tidak valid |
| 402 | Pembayaran gagal: `INSUFFICIENT_FUNDS` (booking) atau `NO_FUNDS_NO_KEY` (unlock) |
| 403 | Akses ditolak, belum verifikasi, atau vendor suspended |
| 404 | Sumber daya tidak ditemukan |
| 409 | Konflik: kendaraan tidak tersedia, batas armada, atau pembatalan terlarang |
| 500 | Kesalahan server |

---

## 10. Komunikasi Real-time

Socket.IO berjalan pada port yang sama dengan API. Saat koneksi, klien mengirim token pada `handshake.auth.token`. Server memverifikasinya dan memasukkan socket ke room sesuai peran:

- `user:{userId}` untuk penyewa.
- `vendor:{vendorId}` untuk vendor.

Koneksi tanpa token valid langsung diputus.

Event yang dipancarkan server:

| Event | Tujuan | Pemicu |
|-------|--------|--------|
| `booking:new` | room vendor | Booking baru dibuat |
| `booking:returned` | room vendor | Kendaraan dikembalikan |
| `booking:cancelled` | room vendor | Booking dibatalkan |
| `vehicle:update` | room vendor (dan penyewa untuk aksi vendor) | Buka/kunci IoT dan telemetri |

Worker telemetry (`telemetry.worker.js`) berjalan tiap 10 detik, memperbarui posisi kendaraan pada seluruh booking aktif dan memancarkan `vehicle:update` ke room vendor terkait.

---

## 11. Keamanan

- Kata sandi disimpan sebagai hash bcrypt (cost 10).
- NIK disimpan ganda: nilai mentah pada `users.nik` dan hash SHA-256 pada `users.nik_hash` yang terindeks.
- Access token JWT berumur pendek (15 menit) ditandatangani `JWT_SECRET`; refresh token berumur 30 hari ditandatangani `REFRESH_SECRET` terpisah.
- Rotasi refresh token: setiap refresh mencabut JTI lama dan menerbitkan yang baru, sehingga token yang dipakai ulang akan ditolak.
- Middleware `authMiddleware` melindungi endpoint penyewa; `vendorMiddleware` memastikan peran vendor.
- Transaksi finansial memakai `FOR UPDATE` untuk mencegah kondisi balapan pada saldo dan ketersediaan kendaraan.
- Frontend menyimpan token di `flutter_secure_storage` dan menyegarkan otomatis saat menerima 401.

Catatan: fallback login demo yang menerima password tertentu hanya aktif pada `NODE_ENV=development` dan harus dimatikan di lingkungan nyata.

---

## 12. Simulasi Layanan Eksternal

Karena ini prototipe akademik, seluruh integrasi pihak ketiga digantikan logika internal:

- **Dukcapil dan Korlantas**: verifikasi identitas pada alur registrasi dan verifikasi memanggil `utils/verify.js`, yang mengueri langsung tabel `dukcapil_datadiri` dan `korlantas_sim`. Endpoint `/api/mock/...` menambahkan jeda buatan untuk meniru latensi jaringan, namun alur utama tidak bergantung padanya.
- **Payment gateway**: tidak ada panggilan eksternal. Pembayaran disimulasikan dengan menerbitkan `gateway_ref` lokal dan memindahkan saldo dompet internal. Endpoint `/api/mock/payment/pre-auth` hanya mengembalikan kode pra-otorisasi palsu.
- **IoT dan GPS**: kunci/buka hanya menulis baris log dan memancarkan event. Lokasi diacak di sekitar koordinat Yogyakarta. Worker telemetry mensimulasikan pergerakan.

---

## 13. Data Demo dan Seed

`database/seed.sql` mengisi lingkungan dengan data bertema Yogyakarta serta data historis enam bulan untuk keperluan dashboard dan analitik.

Ringkasan isi seed:

- 35 entri data Dukcapil dan SIM (10 inti + 25 tambahan).
- 3 paket langganan, 3 vendor (Rental Pak Haji, MotorKu Yogya, Trans Jogja Rent).
- 30 penyewa (5 inti + 25 historis) dengan distribusi level yang beragam.
- 15 kendaraan motor tersebar di tiga vendor.
- 6 geofence (garasi vendor, stasiun, bandara, mal, kampus).
- Akun dompet multi metode beserta transaksi top up.
- 1 booking aktif untuk demo IoT, 60 booking historis berstatus `completed`, dan 1 booking demo denda keterlambatan.
- Sekitar 40 ulasan dari booking historis.

Akun demo utama:

| Peran | Email | Password |
|-------|-------|----------|
| Penyewa | demo@renthub.id | demo1234 |
| Penyewa saldo kecil | poor@renthub.id | demo1234 |
| Vendor | pakhaji@rental.id | vendor@123 |

Daftar lengkap akun dan data identitas ada di [README.md](README.md).

---

## 14. Batasan, Asumsi, dan Catatan Diskrepansi

### 14.1 Batasan dan Asumsi

- Sistem hanya melayani sepeda motor; enum `vehicles.jenis` dikunci ke `motor` dan hanya SIM C yang diterima.
- Booking langsung menjadi `active` setelah pembayaran; status `pending` dan `confirmed` ada di enum namun tidak dipakai alur saat ini.
- Tidak ada penarikan saldo vendor ke bank nyata; `vendors.saldo` hanya bertambah secara internal.
- Tidak ada peran administrator platform.
- Auto-suspend dievaluasi saat aksi tertentu (booking, tambah armada), bukan sebagai job terjadwal.

### 14.2 Catatan Diskrepansi (untuk perbaikan dokumentasi atau kode)

Selama analisis ditemukan beberapa ketidaksesuaian antara dokumentasi pendukung dan kode aktual. Dicatat di sini agar transparan:

1. **Jumlah tabel**: `CLAUDE.md` menyebut "13 tabel + 2 view", sedangkan skema aktual berisi 19 tabel + 2 view. Dokumen ini mengikuti skema aktual.
2. **Berkas whitelist identitas**: `CLAUDE.md` menyebut `backend/seed/valid_nik.json` dan `valid_sim.json`, sedangkan berkas yang ada bernama `valid_niks.json` dan `valid_sims.json`. Selain itu, alur verifikasi aktual (`utils/verify.js`) memvalidasi terhadap tabel `dukcapil_datadiri` dan `korlantas_sim`, bukan terhadap berkas JSON tersebut. Berkas JSON kini bersifat referensi yang tidak terpakai.
3. **Event socket unlock**: `CLAUDE.md` menyebut event `vehicle:unlocked` ke room penyewa, sedangkan kode memancarkan `vehicle:update` untuk perubahan kunci. Dokumen ini mengikuti kode.
4. **Database pada log startup**: `app.js` mencetak "Database: MySQL (XAMPP)" dan `database.js` menyebut "XAMPP", padahal lingkungan pengembangan yang digunakan adalah Laragon. Tidak berpengaruh fungsional.
5. **Variabel trust tambahan**: berkas `.env` pengembangan memuat `TRUST_SCORE_PELANGGARAN_LOKASI` dan `TRUST_SCORE_CANCEL` yang tidak direferensikan kode (kode memakai `TRUST_SCORE_GEOFENCE_BREACH` untuk pelanggaran lokasi dan tidak memberi penalti trust pada pembatalan).
6. **Kredensial di dokumentasi**: `changedb.md` mencantumkan kredensial database cloud (Railway) secara terbuka. Untuk keamanan, sebaiknya dipindahkan ke variabel lingkungan dan tidak disimpan di repositori.

Catatan ini tidak mengubah perilaku sistem; tujuannya memberi gambaran jujur kepada pembaca dan menjadi daftar pekerjaan kebersihan dokumentasi.
