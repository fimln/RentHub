# RentHub

> Platform agregator penyewaan motor cerdas dengan verifikasi identitas, dompet digital, kunci pintar (IoT), dan pelacakan lokasi real-time.

RentHub adalah prototipe purwarupa (proof of concept) sebuah marketplace sewa motor yang menghubungkan penyewa dengan banyak vendor rental. Aplikasi ini dibangun oleh Kelompok 1 (PT. RenthubIndo) sebagai proyek sprint mata kuliah Pengembangan Perangkat Lunak (PPL), Universitas Gadjah Mada, 2026.

Seluruh integrasi pihak ketiga (Dukcapil, Korlantas, payment gateway, dan perangkat IoT/GPS) disimulasikan di dalam sistem sehingga aplikasi dapat berjalan penuh tanpa koneksi ke layanan eksternal apa pun.

Dokumen spesifikasi lengkap (single source of truth) tersedia di [SPECS.md](SPECS.md). Diagram arsitektur dan alur bisnis ada di [diagrams.md](diagrams.md).

---

## Daftar Isi

- [Tim Pengembang](#tim-pengembang)
- [Fitur Utama](#fitur-utama)
- [Arsitektur](#arsitektur)
- [Teknologi](#teknologi)
- [Prasyarat](#prasyarat)
- [Panduan Instalasi](#panduan-instalasi)
- [Akun Demo](#akun-demo)
- [Data Identitas untuk Verifikasi](#data-identitas-untuk-verifikasi)
- [Struktur Proyek](#struktur-proyek)
- [Pengujian](#pengujian)
- [Pemecahan Masalah](#pemecahan-masalah)
- [Dokumentasi Lanjutan](#dokumentasi-lanjutan)

---

## Tim Pengembang

**Kelompok 1**

- Nama kelompok: RentHub
- Nama perusahaan: PT. RenthubIndo

| Nama | Jabatan |
|------|---------|
| Gilbert Fandiliam Mooy | Chief Executive Officer (CEO) |
| Alfi Maulana Akbar | Chief Technology Officer (CTO) |
| Engelbertus Rande | Chief Product Officer (CPO) |
| Zildan Alfatif Agustian | Chief Operating Officer (COO) |

---

## Fitur Utama

**Sisi Penyewa**

- Registrasi dengan verifikasi identitas otomatis (NIK ke Dukcapil, SIM C ke Korlantas).
- Trust score dinamis dengan empat level (bronze, silver, gold, platinum).
- Dompet digital multi metode (GoPay, OVO, DANA, kartu debit, BCA VA, Mandiri VA) dengan buku besar audit.
- Pemesanan dengan estimasi biaya transparan, tarif per jam atau per hari, opsi antar, dan deposit virtual.
- Pembayaran atomik dengan prinsip pra-otorisasi: dana ditahan saat booking dan dilepas saat pengembalian.
- Kunci pintar IoT: buka dan kunci motor lewat aplikasi memakai token unik ("No Funds, No Key").
- Pelacakan lokasi motor secara real-time melalui Socket.IO.
- Pengembalian dengan validasi geofence, perhitungan denda keterlambatan, dan refund deposit otomatis.
- Ulasan dan rating untuk motor yang sudah dipakai.

**Sisi Vendor**

- Dashboard agregat: pendapatan, jumlah armada, status unit, dan rating.
- Manajemen armada (tambah, ubah, nonaktifkan) dengan verifikasi STNK ke Korlantas.
- Paket langganan berjenjang (starter, profesional, enterprise) dengan batas armada dan komisi platform berbeda.
- Penangguhan akun otomatis (auto-suspend) jika langganan jatuh tempo.
- Kontrol kunci jarak jauh (force lock, emergency lock, unlock) atas armada sendiri.
- Pembebasan denda (waive) kepada penyewa beserta refund-nya.

---

## Arsitektur

```
Flutter (mobile/web)  <-- HTTP REST + WebSocket -->  Node.js / Express  <-->  MySQL 8
                                                            |
                                                  Simulasi layanan eksternal:
                                                  Dukcapil, Korlantas,
                                                  payment gateway, IoT/GPS
```

- **Frontend**: Flutter, manajemen state dengan Provider, komunikasi via `http` dan `socket_io_client`.
- **Backend**: Express dengan 12 modul route di bawah prefix `/api`, Socket.IO untuk event real-time, dan worker telemetry yang mensimulasikan pergerakan GPS.
- **Database**: MySQL 8 (dijalankan via Laragon di lingkungan pengembangan), 19 tabel dan 2 view.

Penjelasan rinci tiap komponen ada di [SPECS.md](SPECS.md).

---

## Teknologi

| Lapisan | Teknologi |
|---------|-----------|
| Frontend | Flutter (Dart), Provider, http, socket_io_client, flutter_map, google_fonts |
| Backend | Node.js, Express, Socket.IO, mysql2, jsonwebtoken, bcrypt, uuid |
| Database | MySQL 8 (Laragon / phpMyAdmin) |
| Pengujian | Jest + Supertest (backend), flutter_test (frontend) |

---

## Prasyarat

| Software | Fungsi | Sumber |
|----------|--------|--------|
| Laragon | Menyediakan MySQL dan phpMyAdmin | laragon.org |
| Node.js (LTS) | Menjalankan backend API | nodejs.org |
| Flutter SDK | Menjalankan aplikasi frontend | flutter.dev |
| VS Code | Editor kode | code.visualstudio.com |
| Android Studio | Hanya untuk emulator Android (opsional) | developer.android.com/studio |

---

## Panduan Instalasi

### 1. Siapkan Database (Laragon + phpMyAdmin)

1. Buka Laragon, klik **Start All**.
2. Klik **Database** untuk membuka phpMyAdmin di browser.
3. Klik **New**, isi nama `renthub_db`, lalu **Create**.
4. Pastikan database `renthub_db` terpilih. Breadcrumb atas harus tertulis `... » Database: renthub_db`. Jika tidak terpilih, import akan gagal dengan error `#1046 - No database selected`.
5. Buka tab **Import**, pilih `database/schema.sql`, lalu **Go**. Harusnya muncul "21 queries executed" tanpa error (19 tabel dan 2 view).
6. Masih di dalam `renthub_db`, **Import** lagi, pilih `database/seed.sql`, lalu **Go**.

> Catatan: `schema.sql` sengaja tidak meng-hardcode nama database agar bisa dipakai untuk `renthub_db` (pengembangan) dan `renthub_test` (pengujian). Karena itu Anda wajib memilih database terlebih dahulu sebelum import.

### 2. Konfigurasi Backend

Buat file `backend/.env`. Anda bisa menyalin dari `backend/.env.example`, lalu sesuaikan bila perlu:

```env
PORT=3000
NODE_ENV=development
DB_HOST=localhost
DB_PORT=3306
DB_NAME=renthub_db
DB_USER=root
DB_PASSWORD=
JWT_SECRET=isi_dengan_secret_acak_anda
REFRESH_SECRET=isi_dengan_secret_acak_berbeda_dari_jwt
JWT_EXPIRES_IN=15m
MOCK_API_DELAY_MS=800
TRUST_SCORE_VERIFY=20
TRUST_SCORE_TEPAT_WAKTU=10
TRUST_SCORE_OVERTIME_RINGAN=-10
TRUST_SCORE_OVERTIME_BERAT=-20
TRUST_SCORE_GAGAL_BAYAR=-5
TRUST_SCORE_GEOFENCE_BREACH=-15
```

### 3. Jalankan Backend

```bash
cd backend
npm install
npm run dev
```

Berhasil jika muncul:

```
RentHub API Server
http://localhost:3000
MySQL connected: 2026-xx-xx ...
```

### 4. Konfigurasi Target Platform Frontend

Buka `frontend/lib/utils/constants.dart` dan sesuaikan `baseUrl` serta `socketUrl`:

- Web browser: `http://localhost:3000`
- Emulator Android: `http://10.0.2.2:3000`
- HP fisik via USB: `http://<IP-komputer>:3000`

Detail lengkap ada di [changedb.md](changedb.md).

### 5. Jalankan Frontend

```bash
cd frontend
flutter pub get
flutter run            # pilih perangkat saat diminta
# atau
flutter run -d chrome  # langsung di browser
```

---

## Akun Demo

Semua akun di bawah berasal dari `database/seed.sql`.

### Penyewa

| Email | Password | Keterangan |
|-------|----------|------------|
| demo@renthub.id | demo1234 | Akun utama demo, saldo total Rp 1.000.000, terverifikasi, trust score 70 |
| poor@renthub.id | demo1234 | Saldo kecil (Rp 50.000), untuk menguji alur gagal bayar |
| budi@example.com | user@123 | Trust score 82 (silver) |
| siti@example.com | user@123 | Trust score 95 (platinum) |
| rudi@example.com | user@123 | Trust score 45 (bronze) |

> Seed juga mengisi 25 penyewa tambahan (`usr-006` hingga `usr-030`) sebagai data historis untuk dashboard dan analitik.

### Vendor

| Email | Password | Keterangan |
|-------|----------|------------|
| pakhaji@rental.id | vendor@123 | Rental Pak Haji, langganan starter |
| motorku@rental.id | vendor@123 | MotorKu Yogya, langganan starter |
| transjogja@rental.id | vendor@123 | Trans Jogja Rent, langganan profesional |

> Seluruh armada bertipe motor. Aplikasi ini memang difokuskan pada penyewaan sepeda motor.

---

## Data Identitas untuk Verifikasi

Saat registrasi atau verifikasi identitas, gunakan salah satu pasangan NIK dan SIM C berikut. Data ini tersimpan di tabel simulasi `dukcapil_datadiri` dan `korlantas_sim`.

NIK (pilih salah satu):

```
3273010101950001  3273020202960002  3273030303970003
3273040404980004  3273050505990005  3271061506870006
3578077507920007  3374088808001008  3175099909851009  3273101010961010
```

SIM (pilih salah satu, semua jenis C):

```
A-9876543210  A-1234567890  A-5555555555  A-1111111111  A-2222222222
B-3333333333  B-4444444444  C-5678901234  C-9012345678  D-1357924680
```

> Hanya SIM berjenis C yang diterima karena objek sewa adalah sepeda motor.

---

## Struktur Proyek

```
RentHub/
├── backend/                 Node.js + Express API
│   ├── .env.example         Template konfigurasi (salin menjadi .env)
│   ├── config/
│   │   └── database.js       Pool koneksi MySQL2
│   ├── seed/
│   │   ├── valid_niks.json   Whitelist NIK (referensi, lihat catatan SPECS)
│   │   └── valid_sims.json   Whitelist SIM (referensi, lihat catatan SPECS)
│   ├── src/
│   │   ├── app.js            Entry point: Express, Socket.IO, worker
│   │   ├── middleware/       authMiddleware, vendorMiddleware
│   │   ├── routes/           12 modul route di bawah /api
│   │   ├── utils/            trust.js, verify.js, wallet.js
│   │   └── workers/          telemetry.worker.js (simulasi GPS)
│   └── tests/               Jest + Supertest (unit, integration, system)
├── database/
│   ├── schema.sql           19 tabel + 2 view
│   └── seed.sql             Data demo (Yogyakarta) dan data historis
├── frontend/                Aplikasi Flutter
│   └── lib/
│       ├── main.dart
│       ├── screens/         Layar penyewa dan vendor (prefiks vendor_)
│       ├── services/        api_service, auth_provider, socket_service
│       ├── utils/           constants.dart (base URL), app_theme.dart
│       └── widgets/
├── SPECS.md                 Spesifikasi lengkap (single source of truth)
├── diagrams.md              Diagram arsitektur dan alur bisnis
├── changedb.md              Panduan ganti koneksi DB dan platform Flutter
└── blackbox_test.md         Catatan pengujian black box
```

---

## Pengujian

Backend memakai Jest dan Supertest dengan database terpisah `renthub_test`. Siapkan database tersebut terlebih dahulu (import `schema.sql` ke `renthub_test`), buat `backend/.env.test`, lalu:

```bash
cd backend
npm test               # jalankan seluruh test
npm run test:coverage  # dengan laporan coverage
```

Frontend:

```bash
cd frontend
flutter test
```

---

## Pemecahan Masalah

**MySQL connection failed**
Pastikan Laragon sudah Start All dan layanan MySQL aktif.

**flutter: connection refused**
Pastikan backend berjalan (`npm run dev`), lalu cek `frontend/lib/utils/constants.dart`. Gunakan `10.0.2.2` untuk emulator Android atau `localhost` untuk web.

**flutter doctor error tentang Android**
Jalankan `flutter doctor --android-licenses`, lalu ketik `y` untuk semua.

**Emulator sangat lambat**
Aktifkan virtualisasi di BIOS (Intel VT-x atau AMD-V), atau gunakan `flutter run -d chrome`.

**Password tidak cocok setelah import seed**
Login sekali memakai password demo. Pada mode development, backend akan otomatis melakukan re-hash password yang benar.

**#1046 - No database selected saat import schema.sql**
Anda mengimpor di level server, bukan di dalam database. Pilih `renthub_db` terlebih dahulu (daftar tabel terlihat di sidebar kiri), baru jalankan Import.

**Reset database dari awal**
Drop `renthub_db`, buat ulang, lalu import `schema.sql` dan `seed.sql` kembali. Jangan import di level server.

---

## Dokumentasi Lanjutan

- [SPECS.md](SPECS.md) - spesifikasi sistem lengkap: aktor, model data, aturan bisnis, formula, dan seluruh endpoint API.
- [diagrams.md](diagrams.md) - diagram alur bisnis, arsitektur berlapis, dan ERD.
- [changedb.md](changedb.md) - cara berpindah antara database lokal dan cloud, serta target platform Flutter.
- [blackbox_test.md](blackbox_test.md) - skenario pengujian black box.

---

Dibuat untuk keperluan akademik. Seluruh integrasi eksternal bersifat simulasi dan tidak terhubung ke layanan nyata mana pun.
