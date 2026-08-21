# Panduan Menjalankan Tulap.id — Step by Step

Ikuti urutan ini persis. Setiap tahap ada cara memverifikasi sebelum lanjut ke tahap berikutnya — jangan lompat tahap kalau tahap sebelumnya belum berhasil.

---

## TAHAP 0 — Prasyarat yang Anda Perlukan

Sebelum mulai, pastikan sudah terinstall di komputer Anda:
- **Node.js** (v18+) — `node -v`
- **PostgreSQL** — bisa lokal (install langsung) atau lewat Docker
- **Flutter SDK** — `flutter doctor` harus hijau semua (minimal Android toolchain)

Kalau PostgreSQL belum ada, cara tercepat pakai Docker:
```bash
docker run --name tulap-postgres -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=tulap_db -p 5432:5432 -d postgres:16
```

**S3 Storage: untuk tahap awal ini, LEWATI dulu.** Anda tidak perlu S3 sungguhan untuk menjalankan Auth, Users, dan Tasks module — hanya endpoint `/evidence/*` (upload foto/nota) yang butuh S3 aktif. Kita test itu belakangan.

---

## TAHAP 1 — Backend Menyala

```bash
cd tulap_backend
npm install @nestjs/passport @nestjs/jwt passport passport-jwt bcrypt \
  @prisma/client class-validator class-transformer @nestjs/config \
  @aws-sdk/client-s3 @nestjs/platform-express multer
npm install -D prisma @types/passport-jwt @types/bcrypt @types/multer ts-node

cp .env.example .env
```

Edit `.env`, minimal isi bagian ini (S3_* boleh dibiarkan nilai placeholder untuk sekarang):
```
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/tulap_db?schema=public"
JWT_SECRET="rahasia-development-boleh-sembarang-untuk-sekarang"
JWT_REFRESH_SECRET="rahasia-development-berbeda-dari-yang-atas"
```

Jalankan migrasi + seed:
```bash
npx prisma generate
npx prisma migrate dev --name init
npx prisma db seed
```

**✅ Verifikasi:** Anda harus melihat output `Role 'PEGAWAI' siap.` dst, dan `Akun Super Admin awal dibuat: superadmin@tulap.id / GantiSegeraSetelahLogin!123`. Kalau tidak muncul, cek `DATABASE_URL` — kemungkinan besar PostgreSQL belum jalan.

Tambahkan script seed ke `package.json` (kalau belum otomatis terbaca):
```json
"prisma": {
  "seed": "ts-node prisma/seed.ts"
}
```

Jalankan server:
```bash
npm run start:dev
```

**✅ Verifikasi:** Buka `http://localhost:3000` di browser — boleh muncul "Cannot GET /" (itu normal, artinya server hidup). Cek log terminal, harus ada baris `Koneksi database PostgreSQL berhasil dibuka.`

**Tes login pertama** (pakai curl, Postman, atau Thunder Client di VS Code):
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"superadmin@tulap.id","password":"GantiSegeraSetelahLogin!123"}'
```
**✅ Verifikasi:** Response harus berisi `accessToken`, `refreshToken`, dan data `user`. Kalau ini berhasil, **seluruh fondasi Auth + RBAC + Database sudah benar jalan.**

---

## TAHAP 2 — Buat Data Uji (Pegawai + Tugas)

Simpan `accessToken` dari langkah di atas, dipakai di header `Authorization: Bearer <token>` untuk semua request berikut.

**Daftarkan satu pegawai:**
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <accessToken_superadmin>" \
  -d '{"fullName":"Budi Santoso","email":"budi@tulap.id","password":"password123","roleName":"PEGAWAI","instansiName":"Dinas PU"}'
```

**Login sebagai pegawai** untuk dapatkan `accessToken` baru miliknya, lalu simpan `id` user Budi dari response register di atas.

**Buat tugas** (masih pakai token Super Admin, karena hanya ADMIN/SUPER_ADMIN yang boleh):
```bash
curl -X POST http://localhost:3000/tasks \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <accessToken_superadmin>" \
  -d '{
    "taskName": "Inspeksi Jembatan",
    "destination": "Jakarta Timur",
    "startDate": "2026-08-10",
    "endDate": "2026-08-12",
    "budgetAmount": 1500000,
    "assigneeId": "<id_budi>"
  }'
```

**✅ Verifikasi:** Response berisi `taskCode` format `TL-202608-0001` dan `status: "DRAFT"`. Simpan `id` tugas ini.

---

## TAHAP 3 — Mobile App Menyala

```bash
cd tulap_mobile
flutter create . --platforms=android,ios   # jika folder platform belum ada
```

Buka `pubspec.yaml`, salin seluruh isi `pubspec_additions.yaml` ke bawah `dependencies:` yang sudah ada, lalu:
```bash
flutter pub get
```

Base URL backend sudah otomatis benar untuk dev lokal (default `http://10.0.2.2:3000`, alias Android emulator ke localhost komputer host) — tidak perlu diedit untuk menjalankan di emulator. Untuk target lain, override lewat `--dart-define` saat `flutter run`, TIDAK perlu mengedit kode:
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000   # iOS Simulator/Chrome
flutter run --dart-define=API_BASE_URL=http://<IP_LAN_komputer_Anda>:3000   # HP fisik
```

Tanpa flag di atas:
```bash
flutter run
```

**✅ Verifikasi:** app menampilkan Login, lalu Beranda dengan data tugas sungguhan setelah login. Login berhasil = seluruh dependency injection, migrasi SQLite, dan koneksi ke backend sudah benar.

---

## Build untuk rilis (APK produksi)

`_kApiBaseUrl` di `lib/app/di/injection_container.dart` dibaca dari `--dart-define=API_BASE_URL=...` saat build — **wajib** disertakan untuk build rilis, kalau tidak app akan tetap menunjuk ke alamat dev lokal (`10.0.2.2`, tidak bisa dijangkau di luar emulator):

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.tulap.id
```

**Signing config sudah nyata (bukan debug key lagi).** `android/key.properties` (digitignore, tidak dikomit) menunjuk ke `android/upload-keystore.jks` (juga digitignore) — keduanya sudah ada di mesin dev ini. `flutter build apk --release` sekarang menghasilkan APK yang ditandatangani dengan keystore rilis sungguhan, bukan debug key. **Kalau clone baru di mesin lain** (atau keystore ini hilang), generate ulang:

```bash
keytool -genkeypair -v -keystore android/upload-keystore.jks \
  -alias tulap_upload -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Tulap.id, OU=Mobile, O=Tulap.id, L=Jayapura, ST=Papua, C=ID"
```

lalu buat `android/key.properties`:
```
storePassword=<password yang tadi diketik ke keytool>
keyPassword=<sama dengan storePassword - PKCS12 tidak mendukung beda password>
keyAlias=tulap_upload
storeFile=upload-keystore.jks
```

**Simpan `upload-keystore.jks` + passwordnya di tempat aman di luar repo** (mis. password manager) — kalau hilang, update APK yang sudah pernah dipublish ke Play Store tidak bisa dilakukan lagi (harus rilis sebagai app baru). Tanpa `key.properties`, build otomatis fallback ke debug signing (tetap bisa `flutter build apk --release` untuk testing, hanya saja hasilnya tidak bisa dipakai untuk update rilis Play Store yang sudah ada.

Yang masih belum diselesaikan sesi ini:
- **Play Console** — keystore ini baru "siap tanda tangan", belum ada akun Google Play Console / listing app yang sebenarnya (itu keputusan & biaya di luar kendali kode).
- **Backend produksi** — `S3_*`, `DATABASE_URL`, `JWT_SECRET`/`JWT_REFRESH_SECRET` di `.env` backend saat ini nilai dev lokal; deployment produksi butuh infrastruktur & secret sungguhan (server, domain, TLS, dsb).

---

## Kemungkinan Error & Solusinya

| Error | Kemungkinan Penyebab |
|---|---|
| `Can't reach database server` | PostgreSQL belum jalan, atau `DATABASE_URL` salah |
| `Role tidak terdaftar di master data` saat register | Lupa jalankan `npx prisma db seed` |
| Mobile: `MissingPluginException` | Jalankan `flutter clean && flutter pub get` lalu restart |
| Mobile: error kompilasi banyak sekali | Kemungkinan ada dependency di `pubspec_additions.yaml` yang belum tersalin ke `pubspec.yaml` |
| `Connection refused` dari mobile ke backend | Base URL salah — default sudah `10.0.2.2` untuk emulator Android, override dengan `--dart-define=API_BASE_URL=...` untuk target lain (lihat TAHAP 3) |

---

## Setelah Tahap 3 Berhasil

Mobile app (login, tugas, kamera geotag, scan nota OCR, sync offline, Lokasi, notifikasi) dan Web Dashboard (`tulap_web` — antrean verifikasi, approve/reject/revisi dengan catatan wajib, generate LPJ PDF, buat tugas baru, kelola pegawai; jalankan `npm install && npm run dev` di situ, lihat `.env.example`) sudah terbukti jalan end-to-end lawan backend lokal. Backend juga sudah punya Audit Trail (`GET /audit-logs`), Notifikasi, dan rate limiting. Yang masih belum ada: RootDetector iOS (baru Android), halaman Peta/Keuangan/Laporan/Pengaturan di Web Dashboard (di luar cakupan MVP per `docs/tulap_product_spec.md` Bagian 38-39), automated test suite (0 test di ketiga codebase), dan env produksi backend sungguhan (lihat "Build untuk rilis" di atas untuk status signing mobile, yang sudah selesai).
