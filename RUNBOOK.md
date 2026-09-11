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

