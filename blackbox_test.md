# Dokumentasi dan Analisis Hasil Pengujian Aplikasi RentHub (Manual & Otomatis)

Dokumen ini menggabungkan dan menyelaraskan hasil pengujian manual (Black Box UI) dan pengujian otomatis (Automated Testing) untuk aplikasi RentHub. Pengujian dilakukan untuk memastikan fungsionalitas aplikasi berjalan sesuai spesifikasi pada sisi penyewa (renter) maupun vendor.

---

## 1. Pengujian Manual Black Box (UI)

Pengujian manual difokuskan pada interaksi antarmuka pengguna (UI) untuk mensimulasikan pengalaman langsung penyewa dan vendor.

### 1.1 Skenario Penyewa (Renter)

| ID | Fitur / Skenario | Prasyarat | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-UI-001** | Booking & Bayar | Login sebagai `demo@renthub.id` | 1. Buka daftar kendaraan.<br>2. Pilih satu kendaraan.<br>3. Atur durasi (misal 1 hari).<br>4. Klik Checkout.<br>5. Pilih metode "gopay".<br>6. Tekan Bayar. | Muncul layar sukses, booking baru berstatus Aktif, dan saldo berkurang sesuai total. | Muncul pop-up "Booking Berhasil!". Ringkasan booking menampilkan Yamaha Mio M3 2022 (Nopol: AK 9012), biaya sewa Rp75.000, total bayar Rp225.000. | Lulus |
| **TC-UI-002** | Batalkan Booking | Memiliki booking Aktif yang belum dibuka kuncinya. | 1. Buka Detail Booking.<br>2. Pilih tab Info.<br>3. Tekan Batalkan Booking.<br>4. Konfirmasi pembatalan. | Status berubah menjadi Dibatalkan, saldo kembali penuh, dan kendaraan tersedia lagi. Tombol batal harus hilang atau ditolak jika Smart Access sudah dibuka. | Halaman Detail Booking memperbarui status kendaraan (Yamaha Mio M3 2022, Vendor: Motorku Yogya). Durasi sewa dibatalkan dan status pembayaran berubah menjadi "refunded". | Lulus |
| **TC-UI-003** | Kembalikan Kendaraan & Lihat Denda | Memiliki booking aktif. | 1. Buka booking aktif.<br>2. Masuk ke Smart Access.<br>3. Tekan Buka Kunci.<br>4. Tekan Kembalikan Kendaraan. | Jika tepat waktu, deposit di-refund. Jika lewat waktu, muncul denda di tab Denda. | Proses buka kendaraan berhasil. Pengembalian selesai dan sistem memicu pesan "Pengembalian berhasil". | Lulus |
| **TC-UI-004** | Beri Ulasan | Memiliki booking dengan status Selesai. | 1. Buka Detail Booking.<br>2. Pilih tab Ulasan.<br>3. Pilih jumlah bintang.<br>4. Kirim ulasan. | Ulasan tersimpan, serta rating kendaraan & vendor otomatis naik. | Input bintang 5 berhasil diberikan dengan komentar kondisi optimal. Sistem memunculkan notifikasi "Ulasan berhasil diterima". | Lulus |
| **TC-UI-005** | Edit Profil | Sudah login ke akun penyewa. | 1. Buka menu Profil.<br>2. Klik Edit.<br>3. Ubah nama atau tempel URL Foto Profil (opsional).<br>4. Tekan Simpan. | Data perubahan tersimpan dan avatar menampilkan foto baru dari URL tersebut. | Profil diperbarui menjadi "Demo Renthub 1". Halaman profil sukses menampilkan daftar saldo e-wallet terintegrasi (Gopay, OVO, DANA, Kartu Debit). | Lulus |

### 1.2 Skenario Vendor

| ID | Fitur / Skenario | Prasyarat | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **TC-UI-010** | Dashboard & Kartu Langganan | Login sebagai `pakhaji@rental.id` | 1. Masuk ke halaman utama dashboard vendor. | Muncul data pendapatan dan kartu langganan yang berisi kategori, komisi %, status, jatuh tempo, jumlah armada, serta rating vendor. | Dashboard "Rental Pak Haji" menampilkan paket Langganan Starter, Rating 4.3 (16 ulasan), Komisi platform 7.00%, Armada 6/5 unit, Jatuh tempo 2027-06-17, dan Pendapatan total Rp3.543.300. | Lulus |
| **TC-UI-011** | Atur Biaya Antar | Login sebagai `pakhaji@rental.id` | 1. Pada kartu langganan, tekan ikon edit pada Biaya antar.<br>2. Isi nominal angka.<br>3. Tekan Simpan. | Nilai biaya antar tersimpan. Saat penyewa memilih opsi "diantar", biaya tersebut muncul di estimasi total. | Nominal berhasil diubah menjadi Rp30.000 per antaran. Muncul konfirmasi "Biaya antar diperbarui" di bagian bawah dashboard. | Lulus |
| **TC-UI-012** | Bebaskan Denda Penyewa | Ada booking dari penyewa yang mengenakan denda. | 1. Buka Daftar Booking.<br>2. Buka detail booking yang dimaksud.<br>3. Tekan tombol Bebaskan pada bagian denda. | Status denda berubah menjadi Dibebaskan dan saldo penyewa otomatis bertambah kembali (refund). | Detail booking unit Honda Beat 2023 milik penyewa "Demo Renthub" dengan Trust Score 75 (gold) diperbarui. Denda Overtime 90 menit senilai Rp28.000 berhasil diubah menjadi "Dibebaskan". | Lulus |
| **TC-UI-013** | Kontrol Kunci dari Vendor | Login sebagai `pakhaji@rental.id` | 1. Masuk ke menu Armada.<br>2. Pilih salah satu kendaraan.<br>3. Pada bagian Kontrol Kunci (Vendor), tekan tombol Buka / Kunci Paksa / Darurat. | Status IoT pada sistem berubah sesuai dengan aksi tombol yang ditekan. | Terbuka status IoT unit Honda Beat 2023 (Nopol: B 1234 H) berada dalam kondisi "Kunci unlocked". Riwayat pemesanan mencatat log "Kendaraan dibuka oleh vendor". | Lulus |
| **TC-UI-014** | Tambah/Edit Armada + URL | Login sebagai `transjogja@rental.id` (paket profesional). | 1. Masuk ke menu Armada.<br>2. Tekan Tambah.<br>3. Isi data kendaraan dan tempel URL Foto publik.<br>4. Tekan Simpan. | Kendaraan baru berhasil muncul di daftar armada lengkap dengan tampilannya fotonya. | Unit Tesla Cybermotor 2025 (Nopol: AB 2345 EF) berhasil masuk ke sistem dengan status awal "Kunci locked" dan belum ada riwayat pemesanan. | Lulus |

### Catatan Akun Demo Pengujian
*   **Penyewa Utama:** `demo@renthub.id` (Password: `demo1234`)
*   **Vendor Utama:** `pakhaji@rental.id` (Password: `vendor@123`)
*   **Vendor Paket Profesional:** `transjogja@rental.id` (Password: `vendor@123`)

---

## 2. Pengujian Otomatis (Automated Testing)

Pengujian otomatis dijalankan menggunakan framework **Jest + Supertest** untuk bagian backend (unit & integrasi API dengan basis data terisolasi `renthub_test`) serta **Flutter test** untuk bagian frontend (unit & widget).

### Ringkasan Eksekusi
*   **Tanggal Eksekusi:** 6 Juni 2026
*   **Lingkungan:** Windows 11, Node.js + Jest 30, MySQL (Laragon) DB `renthub_test`, Flutter test
*   **Backend Suite:** 14 suite, semua lulus
*   **Backend Kasus Uji:** 68 kasus, semua lulus (Durasi ~6,2 detik)
*   **Frontend Kasus Uji:** 9 kasus, semua lulus
*   **Total Kasus Uji:** 77 kasus lulus, 0 gagal
*   **Tingkat Keberhasilan:** 100%

### A. Pengujian Unit Backend - Util Trust Score (`trust.test.js`)
*Prasyarat umum: Fungsi levelFromScore dimuat.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-TRUST-001 | Penentuan level dari skor | Panggil `levelFromScore(49)` | Level = bronze (batas bawah silver) | bronze | Lulus |
| TC-TRUST-002 | Penentuan level dari skor | Panggil `levelFromScore(50)` | Level = silver | silver | Lulus |
| TC-TRUST-003 | Penentuan level dari skor | Panggil `levelFromScore(74)` | Level = silver (batas atas) | silver | Lulus |
| TC-TRUST-004 | Penentuan level dari skor | Panggil `levelFromScore(75)` | Level = gold (batas bawah) | gold | Lulus |
| TC-TRUST-005 | Penentuan level dari skor | Panggil `levelFromScore(89)` | Level = gold (batas atas) | gold | Lulus |
| TC-TRUST-006 | Penentuan level dari skor | Panggil `levelFromScore(90)` | Level = platinum (batas bawah) | platinum | Lulus |
| TC-TRUST-007 | Penentuan level dari skor | Panggil `levelFromScore(100)` | Level = platinum | platinum | Lulus |
| TC-TRUST-008 | Penentuan level dari skor | Panggil `levelFromScore(0)` | Level = bronze | bronze | Lulus |

### B. Pengujian Unit Backend - Verifikasi NIK & SIM (`verify.test.js`)
*Prasyarat umum: Seed data `dukcapil_datadiri` & `korlantas_sim` pada database pengujian.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-VRF-001 | Verifikasi NIK | `verifyNik` (NIK valid dari seed) | Cocok, data Dukcapil dikembalikan | valid | Lulus |
| TC-VRF-002 | Verifikasi NIK | `verifyNik` (NIK tidak ada di whitelist) | Tidak ditemukan, akses ditolak | ditolak | Lulus |
| TC-VRF-003 | Validasi format NIK | `verifyNik` (< 16 digit) | Format salah, akses ditolak | ditolak | Lulus |
| TC-VRF-004 | Validasi format NIK | `verifyNik` (mengandung huruf) | Format salah, akses ditolak | ditolak | Lulus |
| TC-VRF-005 | Validasi input NIK | `verifyNik(null)` | Input kosong ditolak | ditolak | Lulus |
| TC-VRF-006 | Validasi input NIK | `verifyNik("")` | Input string kosong ditolak | ditolak | Lulus |
| TC-VRF-007 | Verifikasi SIM | `verifySim` (SIM C aktif dari seed) | Valid | valid | Lulus |
| TC-VRF-008 | Verifikasi SIM | `verifySim` (SIM tidak ada) | Status expired atau ditolak | ditolak | Lulus |
| TC-VRF-009 | Validasi input SIM | `verifySim(null)` | Input kosong ditolak | ditolak | Lulus |

### C. Pengujian Integrasi Backend - Autentikasi (`auth.test.js`)
*Prasyarat umum: DB ter-seed, data pengguna uji menggunakan format email `test+...`.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-AUTH-001 | Registrasi | POST `/api/auth/register` dengan NIK & SIM valid | HTTP 201, akun dibuat, identitas terverifikasi | 201 terverifikasi | Lulus |
| TC-AUTH-002 | Registrasi (Negatif) | Register dengan NIK di luar whitelist | Ditolak | ditolak | Lulus |
| TC-AUTH-003 | Registrasi (Negatif) | Register dengan SIM di luar whitelist | Ditolak | ditolak | Lulus |
| TC-AUTH-004 | Registrasi (Negatif) | Register dengan email yang sudah terpakai | Ditolak (konflik data) | ditolak | Lulus |
| TC-AUTH-005 | Login | POST `/api/auth/login` dengan kredensial benar | HTTP 200, mengembalikan access + refresh token | 200 + token | Lulus |
| TC-AUTH-006 | Login (Negatif) | Login dengan password salah | HTTP 401 Unauthorized | 401 | Lulus |

### D. Pengujian Integrasi Backend - Rotasi Token (`auth.refresh.test.js`)
*Prasyarat umum: Pengguna sudah login dan memegang refresh token yang sah.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-AUTH-007 | Refresh Token | POST `/api/auth/refresh` dengan token sah | HTTP 200, mengembalikan access token baru | 200 token baru | Lulus |
| TC-AUTH-008 | Refresh Token (Negatif) | Refresh menggunakan string tidak valid | HTTP 401 | 401 | Lulus |
| TC-AUTH-009 | Rotasi Token | Pakai ulang refresh token lama setelah rotasi dilakukan | HTTP 401 (JTI sudah ditandai invalid) | 401 | Lulus |
| TC-AUTH-010 | Validasi Input | Refresh tanpa menyertakan field `refresh_token` | HTTP 400 Bad Request | 400 | Lulus |

### E. Pengujian Integrasi Backend - Booking & Estimasi (`booking.test.js`)
*Prasyarat umum: DB ter-seed, armada tersedia (available), dan pengguna uji berstatus terverifikasi.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-BOOK-001 | Estimasi Biaya | POST `/api/bookings/estimate` normal | Rincian perhitungan biaya sewa & deposit benar | rincian benar | Lulus |
| TC-BOOK-002 | Estimasi (Negatif) | Estimasi dengan `vehicle_id` yang tidak terdaftar | HTTP 404 Not Found | 404 | Lulus |
| TC-BOOK-003 | Buat Booking | POST `/api/bookings` saat saldo pengguna mencukupi | HTTP 201, status sewa active, status armada rented | 201 active | Lulus |
| TC-BOOK-004 | Buat Booking (Negatif) | Buat booking saat saldo tidak mencukupi | Ditolak dengan HTTP 402 Payment Required | 402 ditolak | Lulus |

### F. Pengujian Integrasi Backend - Pembayaran & Refund (`payment.test.js`)
*Prasyarat umum: Pengguna uji terverifikasi, armada tersedia.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-PAY-001 | Pre-auth Deposit | Booking dengan saldo mencukupi | Nominal deposit ditahan, status transaksional `pre_authorized` | pre_authorized | Lulus |
| TC-PAY-002 | Pre-auth (Negatif) | Booking dengan kondisi saldo kurang | Proses pembuatan data transaksi ditolak | ditolak | Lulus |
| TC-PAY-003 | Refund Deposit | POST `/:id/return` dalam kondisi tepat waktu | Dana deposit dikembalikan penuh ke saldo | refund penuh | Lulus |

### G. Pengujian Integrasi Backend - Pembatalan Booking (`booking.cancel.test.js`)
*Prasyarat umum: Memiliki data booking dengan status aktif.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-CANCEL-001 | Batalkan Booking | Pembatalan booking aktif yang belum pernah di-unlock | Refund penuh, armada kembali available, status berubah menjadi cancelled | refund penuh, available | Lulus |
| TC-CANCEL-002 | Batal (Negatif) | Pembatalan dicoba setelah status armada di-unlock | Ditolak dengan respons HTTP 409 Conflict | 409 | Lulus |
| TC-CANCEL-003 | Batal (Negatif) | Pembatalan dicoba pada data booking yang bukan berstatus active | HTTP 400 Bad Request | 400 | Lulus |

### H. Pengujian Integrasi Backend - Dompet / E-Wallet (`wallet.test.js`)
*Prasyarat umum: Pengguna memiliki saldo di akun dompet digital (misal Gopay).*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-WAL-001 | Potong Saldo Metode | Booking sukses | Nilai saldo pada tabel `ewallet_accounts` (gopay) berkurang | saldo berkurang | Lulus |
| TC-WAL-002 | Potong Saldo Agregat | Booking sukses | Field `users.saldo_ewallet` berkurang senilai total bayar | sesuai total | Lulus |
| TC-WAL-003 | Refund Saldo | Proses return diselesaikan tepat waktu | Saldo deposit dikembalikan ke field `users.saldo_ewallet` | saldo kembali | Lulus |
| TC-WAL-004 | Konsistensi API | Panggil GET `/api/users/profile` pasca-booking | Nilai `saldo_ewallet` yang dikembalikan API ikut berkurang | berkurang | Lulus |

### I. Pengujian Integrasi Backend - Top-up & Ledger (`ewallet.test.js`)
*Prasyarat umum: Pengguna uji memiliki akun e-wallet.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-EWL-001 | Top-up | POST `/api/ewallet/topup` dengan parameter valid | Saldo akun bertambah | saldo bertambah | Lulus |
| TC-EWL-002 | Audit Ledger | Melakukan pengisian saldo (top-up) | Tercatat baris baru pada `ewallet_transactions` dengan tipe 'topup' | baris tercatat | Lulus |
| TC-EWL-003 | Validasi Nominal | Top-up dengan nilai nominal 0 atau minus | Proses ditolak oleh sistem | ditolak | Lulus |
| TC-EWL-004 | Validasi Metode | Top-up menggunakan metode pembayaran tidak terdaftar | HTTP 404 Not Found | 404 | Lulus |
| TC-EWL-005 | Sinkron Agregat | Melakukan top-up | Nilai aggregate field `users.saldo_ewallet` diperbarui | diperbarui | Lulus |
| TC-EWL-006 | Riwayat Transaksi | GET `/api/ewallet/transactions` | Mengembalikan data dalam bentuk array objek | array | Lulus |
| TC-EWL-007 | Riwayat Transaksi | Memeriksa list riwayat setelah proses top-up | Entri aktivitas top-up yang baru dilakukan muncul | muncul | Lulus |
| TC-EWL-008 | Filter Metode | Melakukan filter dengan parameter `metode_bayar=ovo` | Data transaksi yang menggunakan metode selain OVO (misal Gopay) terfilter | terfilter | Lulus |

### J. Pengujian Integrasi Backend - Bebaskan Denda (`penalty.waive.test.js`)
*Prasyarat umum: Terdapat data sewa dengan denda berstatus 'deducted' milik vendor uji.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-WAIVE-001 | Bebaskan Denda | POST `/api/vendors/penalties/:id/waive` | Dana denda dikembalikan ke penyewa, status berubah menjadi 'waived' | waived + refund | Lulus |
| TC-WAIVE-002 | Bebaskan (Negatif) | Membebaskan denda yang statusnya sudah 'waived' | Ditolak dengan respons HTTP 400 Bad Request | 400 | Lulus |
| TC-WAIVE-003 | Otorisasi | Akun vendor lain mencoba membebaskan denda | Ditolak dengan respons HTTP 403 Forbidden | 403 | Lulus |

### K. Pengujian Integrasi Backend - Ulasan & Rating (`review.test.js`, `vendor.rating.test.js`)
*Prasyarat umum: Terdapat data booking berstatus completed milik pengguna terkait.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-REV-001 | Kirim Ulasan | POST `/api/reviews` pada data booking yang sudah selesai | Data ulasan berhasil disimpan ke basis data | tersimpan | Lulus |
| TC-REV-002 | Validasi Rating | Mengirimkan nilai rating di luar rentang angka 1-5 | Proses ditolak oleh validasi sistem | ditolak | Lulus |
| TC-REV-003 | Cegah Ganda | Mengirimkan ulasan kedua kalinya pada satu ID booking yang sama | Ditolak dengan respons HTTP 409 Conflict | 409 | Lulus |
| TC-REV-004 | Agregasi Kendaraan | Mengirimkan ulasan valid | Nilai field `rating_avg` pada data armada diperbarui | diperbarui | Lulus |
| TC-REV-005 | Ulasan Publik | GET `/api/reviews/vehicle/:id` | Daftar ulasan publik untuk armada tersebut berhasil dimuat | tampil | Lulus |
| TC-REV-006 | Cek Status Ulasan | Jalankan fungsi GET review untuk sewa yang belum diulas | Sistem mengembalikan nilai null | null | Lulus |
| TC-REV-007 | Cek Status Ulasan | Jalankan fungsi GET review setelah ulasan dikirim | Data detail review berhasil dikembalikan | data ada | Lulus |
| TC-RATE-001 | Agregasi Vendor | Mengirimkan ulasan valid dari penyewa | Nilai aggregate field `rating_avg` milik vendor diperbarui | diperbarui | Lulus |

### L. Pengujian Integrasi Backend - CRUD Armada & Dashboard Vendor (`vendor.test.js`)
*Prasyarat umum: Login sebagai akun vendor uji.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-VEN-001 | List Armada | GET `/api/vendors/fleet` | HTTP 200, mengembalikan array list kendaraan milik vendor | array | Lulus |
| TC-VEN-002 | Tambah Armada | POST `/api/vendors/fleet` (menyertakan parameter `foto_url`) | HTTP 201, mengembalikan parameter `vehicle_id` baru | 201 dibuat | Lulus |
| TC-VEN-003 | Edit Armada | PUT `/api/vendors/fleet/:id` (mengubah properti warna unit) | HTTP 200, data entitas pada database terupdate | terupdate | Lulus |
| TC-VEN-004 | Nonaktifkan Armada | DELETE `/api/vendors/fleet/:id` | HTTP 200, status data armada berubah menjadi inactive | inactive | Lulus |
| TC-VEN-005 | Dashboard Vendor | GET `/api/vendors/dashboard` | HTTP 200, mengembalikan ringkasan data statistik performa | stats ada | Lulus |

### M. Pengujian Integrasi Backend - Notifikasi (`notification.test.js`)
*Prasyarat umum: Akun user dan vendor tersedia dengan kondisi database ter-seed.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| TC-NOTIF-001 | List Notifikasi | GET `/api/notifications` dengan menyertakan token auth | HTTP 200, mengembalikan array berisi daftar notifikasi | array | Lulus |
| TC-NOTIF-002 | Notifikasi Vendor | Memeriksa notifikasi setelah alur booking sukses | Vendor menerima record notifikasi berkategori `vehicle rented` | ada notif | Lulus |
| TC-NOTIF-003 | Otorisasi | GET `/api/notifications` tanpa menyertakan token auth | Ditolak dengan respons HTTP 401 Unauthorized | 401 | Lulus |

### N. Pengujian Frontend Flutter - Unit & Widget
*Prasyarat umum: Berjalan pada lingkungan isolasi flutter test tanpa membutuhkan koneksi backend nyata.*

| ID | Fitur / Skenario | Skenario / Langkah Uji | Hasil yang Diharapkan | Hasil Aktual | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| FE-API-001 | `ApiService.buildUrl` | Menggabungkan komponen `baseUrl` dan `path` | Struktur URL hasil penggabungan terbentuk dengan benar | benar | Lulus |
| FE-API-002 | `ApiService.buildUrl` | Menjalankan `buildUrl` dengan parameter path tanpa slash depan | Struktur URL tetap terbentuk dengan format yang benar | benar | Lulus |
| FE-AUTH-001 | `AuthProvider` State Awal | Inisialisasi provider pertama kali | Keadaan objek user bernilai null dan status `isLoggedIn` bernilai false | sesuai | Lulus |
| FE-AUTH-002 | `AuthProvider` State Awal | Inisialisasi provider pertama kali | Nilai `isLoading` berstatus false dan objek error bernilai null | sesuai | Lulus |
| FE-LOGIN-001 | Widget `LoginScreen` | Proses render halaman login aplikasi | Terdapat 2 field input (TextField) beserta tombol Masuk di layar | muncul | Lulus |
| FE-LOGIN-002 | Validasi Form Login | Menekan tombol submit dengan kondisi field email kosong | Teks pesan penanda error validasi muncul di layar | error tampil | Lulus |
| FE-CARD-001 | Widget `VehicleCard` | Proses render komponen kartu informasi armada | Teks nama kendaraan beserta harga sewa berhasil tampil | tampil | Lulus |
| FE-CARD-002 | Widget `VehicleCard` | Proses render komponen dengan parameter harga bernilai nol | Komponen tetap ter-render normal tanpa memicu exception | render | Lulus |
| FE-SMOKE-001 | Smoke Test | Membangun struktur widget placeholder utama | Widget ter-build sempurna tanpa menghasilkan exception | lulus | Lulus |

---

## 3. Pemetaan Pengujian Manual ke Pengujian Otomatis

Tabel penjaminan mutu ini memetakan cakupan uji manual antarmuka (UI) ke pengujian otomatis pada level fungsionalitas API backend dan fungsionalitas unit frontend.

| ID Manual | Skenario Manual | Kasus Uji Otomatis Terkait | Keterangan Cakupan & Validasi |
| :--- | :--- | :--- | :--- |
| **TC-UI-001** | Booking + bayar (penyewa) | TC-BOOK-003, TC-PAY-001, TC-WAL-001, TC-WAL-002 | Tercakup penuh pada lapisan fungsionalitas API. Menjamin pengurangan saldo logis dan perubahan status entitas booking. |
| **TC-UI-002** | Batalkan booking | TC-CANCEL-001, TC-CANCEL-002, TC-CANCEL-003 | Tercakup penuh. Mengunci fungsionalitas pembatalan agar tidak bisa dieksekusi sepihak jika status kendaraan sudah di-unlock. |
| **TC-UI-003** | Kembalikan kendaraan & denda | TC-PAY-003, TC-WAL-003, TC-WAIVE-001 | Proses kalkulasi dan pengembalian dana deposit tercakup di API. Mekanisme penalti disimulasikan lewat skenario penyiapan data. |
| **TC-UI-004** | Beri ulasan | TC-REV-001, TC-REV-004, TC-RATE-001 | Tercakup penuh di level backend untuk proses penyimpanan ulasan serta pembaruan nilai rata-rata rating armada dan vendor. |
| **TC-UI-005** | Edit profil | FE-AUTH-001, FE-AUTH-002 | Tercakup sebagian. Validasi state manajemen diuji secara otomatis pada komponen frontend, namun visualisasi perubahan foto dari URL eksternal hanya diverifikasi lewat uji manual UI. |
| **TC-UI-010** | Dashboard & langganan | TC-VEN-005 | Tercakup penuh untuk validasi ketersediaan data agregat statistik yang disajikan pada dashboard vendor. |
| **TC-UI-011** | Atur biaya antar | *Belum ada uji otomatis* | Celah pengujian otomatis. Alur konfigurasi biaya pengantaran end-to-end sejauh ini murni mengandalkan verifikasi manual pada antarmuka. |
| **TC-UI-012** | Bebaskan denda penyewa | TC-WAIVE-001, TC-WAIVE-002, TC-WAIVE-003 | Tercakup penuh untuk validasi logika pengembalian dana denda ke penyewa serta hak akses pembatalan denda antar-vendor. |
| **TC-UI-013** | Kontrol kunci IoT vendor | *Belum ada uji otomatis* | Celah pengujian otomatis. Interaksi langsung perangkat keras IoT dengan antarmuka pengguna saat ini baru diuji lewat metode manual. |
| **TC-UI-014** | Tambah/edit armada + foto | TC-VEN-002, TC-VEN-003 | Tercakup penuh untuk lapisan penyimpanan data. Memastikan parameter string alamat URL foto tersimpan dengan benar di kolom basis data. |

---

## 4. Analisis Hasil dan Rekomendasi

1.  **Metrik Keberhasilan Sempurna:** Seluruh skenario uji yang dieksekusi, baik secara manual maupun otomatis, mencatatkan tingkat kelulusan 100% (77 kasus uji otomatis dan 10 skenario manual utama berstatus lulus). Logika inti yang menyangkut autentikasi, transaksi finansial dompet digital, pembatasan status sewa, pembatalan sewa, penalti denda, serta manipulasi data armada sudah berjalan sesuai dengan spesifikasi teknis yang direncanakan.
2.  **Kesenjangan Pengujian (Testing Gaps):** Berdasarkan hasil pemetaan, terdapat beberapa fungsi kritis yang belum ter-cover oleh skenario uji otomatis, yaitu:
    *   **Logika IoT Vendor (TC-UI-013):** Komunikasi data antara perintah tombol di UI dengan perubahan riil status IoT belum dipayungi oleh integration test terotomatisasi. Hal ini berisiko memunculkan regresi jika ada pembaruan pustaka komunikasi data atau firmware.
    *   **Perhitungan Biaya Antar (TC-UI-011):** Perubahan nominal biaya antar belum diverifikasi otomatis pada fungsionalitas total estimasi biaya sewa di sisi backend.
    *   **Render Gambar Eksternal (TC-UI-005):** Kemampuan aplikasi dalam memuat string URL foto profil menjadi objek visual di komponen avatar belum diuji menggunakan pengujian widget frontend.
3.  **Kualitas Lingkungan Pengujian:** Arsitektur pengujian otomatis dinilai baik karena backend memanfaatkan basis data terisolasi `renthub_test` yang secara mandiri melakukan proses pengosongan dan pengisian data contoh (seeding) sebelum dan sesudah pengujian dijalankan. Hal ini memastikan isolasi state dan menjamin bahwa proses eksekusi uji berulang tidak akan merusak data demonstrasi pada lingkungan pengembangan lokal.

---

## 5. Panduan Menjalankan Ulang Pengujian

### 5.1 Eksekusi Backend Suite (Unit & Integrasi API)
Masuk ke direktori backend, pastikan skema basis data pengujian telah disiapkan melalui file `schema.sql` dan diisi menggunakan `seed.sql` di database server lokal.
```bash
cd backend
npm test
```

### 5.2 Eksekusi Frontend Suite (Unit & Widget Test)
Jalankan perintah pengujian bawaan Flutter pada direktori frontend untuk memastikan komponen state provider dan komponen widget dasar berfungsi normal.
```bash
cd frontend
flutter test
```
