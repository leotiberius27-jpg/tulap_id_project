# Panduan Menjalankan Tulap.id — Step by Step (Mobile & Backend API)

Ikuti urutan ini persis. Setiap tahap ada cara memverifikasi sebelum lanjut ke tahap berikutnya.

---

## TAHAP 0 — Prasyarat yang Anda Perlukan

Sebelum mulai, pastikan sudah terinstall di komputer Anda:
- **Node.js** (v18+) — `node -v`
- **PostgreSQL** — bisa lokal atau lewat Docker:
  ```bash
  docker run --name tulap-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=tulap_db -p 5432:5432 -d postgres:16
  ```
- **Flutter SDK** — `flutter doctor` harus hijau (minimal Android toolchain)

---

## TAHAP 1 — Backend Menyala & Teruji

```bash
cd tulap_backend
npm install
cp .env.example .env
```

Edit `.env` (minimal isi `DATABASE_URL`, `JWT_SECRET`, `JWT_REFRESH_SECRET`).

Jalankan migrasi + seed database:
```bash
npx prisma generate
npx prisma migrate dev --name init
npx prisma db seed
```

**✅ Verifikasi:** Seluruh role dan akun awal Super Admin siap.

**Jalankan Automated Test Suite:**
```bash
npm test
```
**✅ Verifikasi:** Seluruh 5 test suites (20 tests) lolos tanpa error.

Jalankan server development:
```bash
npm run start:dev
```

---

## TAHAP 2 — Menjalankan Aplikasi Mobile

```bash
cd tulap_mobile
flutter pub get
```

**Jalankan Automated Test Suite Mobile:**
```bash
flutter test
```
**✅ Verifikasi:** Seluruh 206 unit/widget tests lolos (`All tests passed!`).

Jalankan di emulator atau perangkat fisik:
```bash
# Android Emulator (default connect ke 10.0.2.2:3000)
flutter run

# HP Fisik (override dengan IP LAN host)
flutter run --dart-define=API_BASE_URL=http://<IP_LAN_KOMPUTER>:3000
```

**⚠️ PENTING - HP fisik via WiFi (bukan `adb reverse`) butuh 2 hal, atau
"tidak dapat terhubung ke server" walau internet aktif:**

1. **IP LAN komputer bisa BERUBAH** (restart router, ganti WiFi, dsb) -
   cek dengan `ipconfig` (cari adapter Wi-Fi aktif), lalu build ULANG
   dengan `--dart-define=API_BASE_URL=http://<IP_LAN_BARU>:3000` setiap
   kali IP-nya berubah. Tanpa dart-define ini, app fallback ke
   `http://127.0.0.1:3000` - alamat itu di HP artinya "diri sendiri",
   BUKAN komputer, jadi selalu gagal connect walau backend & internet
   sama-sama menyala.
2. **Windows Firewall memblokir koneksi masuk secara default** kalau
   profil WiFi-nya "Public" (bukan "Private") - tambahkan rule sekali
   saja per port (PowerShell **as Administrator**). Backend (port
   3000) DAN MinIO (port 9000, penyimpanan foto/nota) butuh rule
   TERPISAH masing-masing - tanpa rule 9000, foto/nota tetap gagal
   ditampilkan walau simpan data teks biasa sudah berhasil:
   ```powershell
   New-NetFirewallRule -DisplayName "Tulap Backend Dev (port 3000)" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -Profile Any
   New-NetFirewallRule -DisplayName "Tulap MinIO Dev (port 9000)" -Direction Inbound -Protocol TCP -LocalPort 9000 -Action Allow -Profile Any
   ```
3. **`S3_PUBLIC_URL_BASE` di `tulap_backend/.env` JANGAN pakai
   "localhost"** - itu ikut tersimpan sebagai `photoUrl`/`scanUrl` yang
   dikirim ke mobile app dan dimuat LANGSUNG oleh HP, "localhost" di HP
   berarti dirinya sendiri. Pakai IP LAN komputer yang SAMA dengan
   `API_BASE_URL` di atas, mis. `http://<IP_LAN_KOMPUTER>:9000/tulap-storage-prod`.
   `S3_ENDPOINT` boleh tetap "localhost" (itu koneksi backend->MinIO,
   sama-sama di komputer ini, tidak lewat jaringan HP sama sekali).
4. **MinIO (`tulap-minio` container Docker) harus benar-benar
   berjalan** - cek dengan `docker ps`, kalau statusnya "Exited" jalankan
   `docker start tulap-minio`. Tanpa ini, upload foto/nota/LPJ/avatar
   GAGAL DI MOBILE dengan pesan **"Tidak dapat terhubung ke server.
   Periksa koneksi internet Anda."** - bukan salah baca koneksi HP,
   tapi request BENAR-BENAR menggantung karena AWS S3 SDK di backend
   retry berkali-kali mencoba konek ke MinIO yang mati sampai melewati
   `receiveTimeout` 30 detik di Dio (mobile), jadi Dio melempar error
   TANPA response sama sekali dari server - persis kejadian nyata yang
   ditemukan 2026-09-16/17 (`tulap-minio` mati sendiri "Exited (255)"
   setelah komputer lama tidak restart Docker Desktop).
5. **`S3_PUBLIC_URL_BASE` yang isinya IP LAN (poin 3 di atas) TIDAK
   otomatis mengikuti kalau IP komputer berubah** (ganti WiFi, DHCP
   renew, restart router) - `photoUrl` yang SUDAH TERSIMPAN di database
   dari upload sebelumnya tetap membawa IP LAMA selamanya (URL final
   disimpan sebagai string utuh saat upload, BUKAN dihitung ulang saat
   dibaca - lihat `S3StorageService.uploadFile()`). Gejalanya BUKAN
   gagal simpan - PATCH/POST berhasil ("Profil berhasil diperbarui"),
   tapi foto tampil kosong/inisial placeholder karena Image.network
   gagal fetch dari IP yang sudah tidak ada. Fix: samakan
   `S3_PUBLIC_URL_BASE` dengan IP LAN AKTIF SEKARANG (`ipconfig` >
   IPv4 Address di adapter WiFi), restart backend, lalu upload ULANG
   foto yang terdampak (foto lama tidak bisa diperbaiki tanpa migrasi
   data manual). Kejadian nyata 2026-09-17: IP berubah dari
   `10.181.220.200` ke `10.230.74.200` di sesi yang sama.

**⚠️ PENTING - Masuk dengan Google/Apple perlu dart-define, SELALU
sertakan di setiap `flutter run`/`flutter build apk` mulai sekarang:**
```bash
--dart-define=GOOGLE_OAUTH_CLIENT_ID=<isi_sama_dengan_.env_backend>
```
`GOOGLE_OAUTH_CLIENT_ID` di `oauth_sign_in_service.dart` dibaca dari
`String.fromEnvironment` saat COMPILE, bukan runtime - build APAPUN
tanpa flag ini menghasilkan APK dengan client ID KOSONG, yang membuat
Google Sign-In gagal (`google_sign_in` tidak bisa menerbitkan idToken
dengan audience yang benar) TANPA request apapun pernah sampai ke
backend - gejalanya persis seperti "Google Sign-In tidak berfungsi"
padahal konfigurasi Firebase/Google Cloud sudah benar. Nilainya HARUS
sama persis dengan `GOOGLE_OAUTH_CLIENT_ID` di `tulap_backend/.env`
(satu OAuth Client ID tipe "Web" dipakai bersama oleh mobile sebagai
`serverClientId` dan backend sebagai `audience` verifikasi). Kejadian
nyata: sesi debugging Maps/FCM/Firestore sempat berulang kali
menjalankan `flutter build apk --debug` polos (tanpa flag ini) dan
menimpa build yang sebelumnya benar di perangkat fisik, membuat Google
Sign-In berhenti bekerja sebagai efek samping tak disengaja. Terjadi
LAGI persis sama tanggal 2026-09-14 (sesi debugging loading Beranda/Peta)
- peringatan tulisan saja tidak cukup, siapapun (termasuk AI assistant)
gampang lupa membaca RUNBOOK sebelum sekadar `flutter run` ulang.

**Mitigasi permanen (sudah dipasang, jangan hapus):**
`tulap_mobile/dart_define.local.json` (di-gitignore, isinya disalin dari
`tulap_backend/.env`) menyimpan `GOOGLE_OAUTH_CLIENT_ID`/`APPLE_OAUTH_CLIENT_ID`
secara permanen di mesin ini, dan run configuration Android Studio
(`.idea/runConfigurations/main_dart.xml`, juga di-gitignore) sudah
diset untuk selalu memakainya lewat `--dart-define-from-file`. Jadi:
- **Lewat Android Studio**: jalankan seperti biasa, flag-nya otomatis ikut.
- **Lewat CLI**: WAJIB pakai
  `flutter run --dart-define-from-file=dart_define.local.json`
  (bukan `flutter run` polos) - kalau file itu belum ada di mesin baru,
  buat dulu dengan menyalin key yang sama dari `tulap_backend/.env`.
- Kode di `oauth_sign_in_service.dart` juga sudah dibuat melempar
  `GoogleSignInMisconfiguredException` dengan pesan jelas (bukan lagi
  "Coba lagi" generik) kalau ini kejadian lagi, supaya sesi berikutnya
  tidak perlu mengulang investigasi logcat dari nol.

**Bug lain yang pernah bikin Google Sign-In gagal total (ditemukan &
diperbaiki 2026-09-16):** `dart_define.local.json` sempat berisi value
dengan tanda kutip literal ikut ter-embed (`"\"774895...com\""`, disalin
apa adanya dari format `.env`), padahal JSON sudah punya kutipnya
sendiri - akibatnya `GOOGLE_OAUTH_CLIENT_ID` yang benar-benar dikirim ke
SDK punya karakter `"` di awal/akhir dan otomatis tidak valid. Value di
file itu harus BARE STRING tanpa kutip tambahan:
```json
{ "GOOGLE_OAUTH_CLIENT_ID": "774895050810-....apps.googleusercontent.com" }
```
Setelah bug itu diperbaiki, gejala berubah jadi `ApiException: 10`
(DEVELOPER_ERROR) - ini SELALU berarti SHA-1 keystore yang dipakai
build saat itu belum/tidak lagi cocok dengan yang terdaftar di Firebase
Console untuk app Android `id.tulap.tulap_mobile` (project
`tulapid-dfaed`). Cara mendiagnosis & memperbaiki cepat lewat CLI (tidak
perlu buka Firebase Console manual):
```bash
# 1) SHA-1 keystore debug yang AKTIF di mesin ini:
keytool -list -v -keystore "$USERPROFILE/.android/debug.keystore" \
  -alias androiddebugkey -storepass android -keypass android | grep SHA1

# 2) SHA-1 yang SUDAH terdaftar di Firebase:
firebase apps:android:sha:list 1:774895050810:android:2da86c4d42f31cc6cc9503 \
  --project tulapid-dfaed

# 3) Kalau tidak cocok, daftarkan yang baru (hilangkan tanda ':'):
firebase apps:android:sha:create 1:774895050810:android:2da86c4d42f31cc6cc9503 \
  <SHA1_TANPA_TITIK_DUA> --project tulapid-dfaed
```
Kejadian nyata 2026-09-16: SHA-1 keystore debug di mesin ini
(`13EED945...`) TIDAK cocok dengan yang terdaftar (`0A4A2210...`), dan
saat dicoba didaftarkan, Firebase menolak dengan `409 ALREADY_EXISTS`
("Oauth client already exists in a different project") - SHA-1 itu
ternyata sudah "dipakai" oleh project Google Cloud lain yang tidak
terlihat oleh akun `leotiberius27@gmail.com` (kemungkinan sisa dari
setup lama). Solusinya BUKAN mengejar project misterius itu, tapi
regenerasi debug keystore baru di mesin ini (`mv
~/.android/debug.keystore ~/.android/debug.keystore.old` lalu
`flutter build apk --debug` - Gradle otomatis bikin yang baru), yang
menghasilkan SHA-1 baru yang pasti belum pernah dipakai di mana pun,
lalu daftarkan itu. Setelah didaftarkan, `google-services.json` juga
di-refresh (`firebase apps:sdkconfig ANDROID <app-id> --project
tulapid-dfaed`) supaya entry `oauth_client` type 1-nya sinkron - live
diverifikasi berhasil login di perangkat fisik.

**Peta Sebaran Lokasi (Beranda) — Google Maps API Key:**

Kartu "Peta & Sebaran Lokasi" di Beranda memakai `google_maps_flutter`.
Tanpa API key, app tetap bisa dibuild dan dijalankan (tidak crash) —
hanya SDK Peta yang menolak menampilkan tile map sungguhan.

1. Buat API key di [Google Cloud Console](https://console.cloud.google.com/)
   > APIs & Services > Credentials, lalu aktifkan **Maps SDK for Android**.
   Batasi key ke package name `id.tulap.tulap_mobile`.
2. Tambahkan baris berikut ke `tulap_mobile/android/local.properties`
   (file ini sudah digitignore, JANGAN pernah dikomit):
   ```
   MAPS_API_KEY=isi_key_android_anda_di_sini
   ```

Sempat dicoba juga alternatif gratis (`flutter_map` + tile OpenStreetMap,
tanpa API key) selama key Google Maps belum tersedia - kalau suatu saat
ingin kembali ke opsi itu, lihat riwayat commit untuk implementasinya.

**⚠️ PENTING - Sync foto/video geotag gagal dengan "Data belum berhasil
dikirim" walau server & storage sudah benar:** `UploadPhotoDto` di
backend memakai `forbidNonWhitelisted: true` (ValidationPipe global) -
kalau `GeotagPhotoModel.toUploadPayload()` di mobile pernah menambah
field baru yang belum ada di DTO (mis. `userId`, `evidenceId`,
`altitude`, `heading`, `verificationStatus` - ditemukan & diperbaiki
2026-09-12), backend menolak SELURUH request dengan 400 SEBELUM pernah
menyentuh service/database - tidak ada log error apapun yang muncul di
konsol backend (ValidationPipe tidak dicatat filter global), jadi
gejalanya terlihat seperti masalah jaringan padahal murni field
mismatch. Kalau item "Foto Kegiatan" di Pusat Sinkronisasi terus gagal
walau MinIO & firewall sudah benar, cek dulu field APAPUN yang dikirim
`toUploadPayload()` benar-benar terdaftar (boleh `@IsOptional()`) di
`UploadPhotoDto`.

**⚠️ PENTING - Foto profil/data lain yang diperbaiki LANGSUNG di
database tidak otomatis terlihat di app:** Sesi mobile membaca profil
dari cache lokal (`flutter_secure_storage`) yang HANYA diperbarui lewat
flow app itu sendiri (login, edit profil). `AuthSessionManager`
sekarang menyegarkan cache ini diam-diam lewat `GET /users/me` setiap
app dibuka (lihat `_refreshFromServerSilently()`), jadi perbaikan data
langsung di database (mis. lewat script one-off) akan ikut tercermin
tanpa perlu logout/login manual - TAPI ini butuh `HomeController` dan
`AccountController` membaca ULANG `AuthSessionManager.currentUser` di
akhir `loadHome()`/`_load()` masing-masing (bukan variabel `user` yang
ditangkap di awal fungsi), karena refresh diam-diam itu bisa selesai
DI TENGAH loadHome()/`_load()` berjalan (keduanya butuh beberapa
network call berurutan) - race condition nyata yang ditemukan langsung
di perangkat fisik 2026-09-12: Akun menampilkan foto benar tapi Beranda
tetap menampilkan inisial sampai race ini diperbaiki.

**Project ini Android-only** - dukungan iOS (folder `ios/`) sudah dihapus
karena tidak ada perangkat/Xcode untuk membangun atau mengujinya. Kalau
suatu saat butuh iOS lagi, jalankan `flutter create --platforms=ios .`
dari `tulap_mobile/` untuk membuat ulang folder platform-nya dari nol
(konfigurasi lama masih ada di riwayat git sebagai referensi).

---

## TAHAP 3 — Build Siap Rilis Play Store

1. **Android App Bundle (Format Resmi Google Play Console):**
```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.tulap.id
```
Output: `build/app/outputs/bundle/release/app-release.aab`

2. **Standalone Release APK (Untuk distribusi langsung / testing):**
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.tulap.id
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

---

## TAHAP 4 — Deployment Backend Produksi (Docker)

Deploy stack backend dan PostgreSQL mandiri:
```bash
cd tulap_backend
docker-compose -f docker-compose.prod.yml up --build -d
```

