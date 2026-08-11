# Tulap.id — Panduan Setup Proyek

Arsip ini berisi seluruh hasil pengembangan Tulap.id sejauh ini. Struktur folder:

```
tulap_id_project/
├── docs/
│   └── tulap_product_spec.md      # Dokumen Product & UI/UX Specification lengkap
├── tulap_backend/                 # NestJS + Prisma + PostgreSQL
│   ├── prisma/schema.prisma
│   ├── src/
│   └── .env.example
├── tulap_mobile/                  # Flutter (Clean Architecture, feature-first)
│   ├── lib/
│   └── pubspec_additions.yaml
└── tulap_web/                     # Design tokens untuk Web Dashboard (React/Next.js)
    ├── styles/design-tokens.css
    └── tailwind.config.js
```

---

## 1. Setup Backend (`tulap_backend/`)

Jika belum punya project NestJS:
```bash
npm i -g @nestjs/cli
nest new tulap_backend_real --skip-git
```
Salin isi folder `tulap_backend/src/` dan `tulap_backend/prisma/` dari arsip ini ke project barumu (timpa folder `src/` bawaan).

Install dependency yang dipakai kode:
```bash
npm install @nestjs/passport @nestjs/jwt passport passport-jwt bcrypt \
  @prisma/client class-validator class-transformer @nestjs/config \
  @aws-sdk/client-s3 @nestjs/platform-express multer pdfkit
npm install -D prisma @types/passport-jwt @types/bcrypt @types/multer @types/pdfkit
```

Siapkan environment:
```bash
cp .env.example .env
# Edit .env: isi DATABASE_URL, JWT_SECRET, JWT_REFRESH_SECRET (openssl rand -base64 64)
```

Jalankan migrasi & server:
```bash
npx prisma generate
npx prisma migrate dev --name init
npm run start:dev
```

**Catatan:** modul `auth`, `users`, `tasks` (+ `checklist`), `evidence` (photo/receipt), dan `lpj` (generate PDF) sudah dibangun. Modul `finance` (rekap/ekspor laporan keuangan sebagai layar tersendiri) masih belum dibangun. Endpoint `POST /lpj/generate` murni generate PDF on-demand dari data tugas VERIFIED yang sudah ada — TIDAK menyimpan record LPJ baru maupun mengunggah ke S3 (skema Prisma belum punya model `LPJ`/`LPJTemplate` yang disebut di Bagian 27 dokumen spesifikasi).

**Catatan penting:** arsip ini TIDAK menyertakan `src/main.ts` (bootstrap NestJS) — file itu dihasilkan otomatis oleh `nest new` dan TIDAK BOLEH ikut tertimpa. Saat "timpa folder `src/` bawaan" di atas, pastikan Anda menyalin folder-folder di dalam `src/` (`common/`, `infrastructure/`, `modules/`, `app.module.ts`) TANPA menghapus `main.ts` yang sudah ada di project baru Anda.

---

## 2. Setup Mobile (`tulap_mobile/`)

Jika belum punya project Flutter:
```bash
flutter create tulap_mobile_real
```
Salin folder `tulap_mobile/lib/` dari arsip ini ke project barumu (timpa `lib/` bawaan).

Buka `pubspec_additions.yaml`, salin seluruh baris di bawah `dependencies:` ke `pubspec.yaml` project asli (di bawah `dependencies:` yang sudah ada), lalu:
```bash
flutter pub get
```

Setelah `flutter create .` menghasilkan folder `android/`, timpa `android/app/src/main/kotlin/<package_id_anda>/MainActivity.kt` bawaan dengan isi `tulap_mobile/android/app/src/main/kotlin/id/tulap/tulap_mobile/MainActivity.kt` dari arsip ini (sesuaikan baris `package` agar sama persis dengan `applicationId` di `android/app/build.gradle` Anda) — ini mengimplementasikan RootDetector secara native untuk Android (heuristik sederhana: build tags, keberadaan binary `su`, aplikasi manajemen root umum). **iOS belum diimplementasikan** — RootDetector akan fail-safe ke `false` di iOS sampai versi Swift-nya dibuat.

**Sebelum aplikasi bisa di-run**, satu hal ini masih perlu dilengkapi:
1. **Session DI untuk ReceiptScannerPage** — SELESAI, lihat `ReceiptScannerEntryPage`.
2. **Flow Login → Beranda** — SELESAI, `main.dart` kini memakai `_AuthGate` yang mengarahkan ke `LoginPage` atau `HomePage` tergantung sesi tersimpan.

---

## 3. Setup Web (`tulap_web/`)

Jika belum punya project (mis. Next.js):
```bash
npx create-next-app@latest tulap_web_real
```
Salin `tulap_web/styles/design-tokens.css` dan `tulap_web/tailwind.config.js` dari arsip ini ke project barumu. Import CSS token di entry point (`_app.tsx` / `app/layout.tsx`) **sebelum** stylesheet Tailwind:
```tsx
import '../styles/design-tokens.css';
import '../styles/globals.css'; // yang berisi @tailwind base/components/utilities
```

**Catatan:** belum ada komponen atau halaman Web Dashboard yang dibangun — baru token desainnya saja.

---

## Fitur yang Sudah Selesai vs Belum

| Fitur | Status |
|---|---|
| Skema Database (Prisma) | ✅ Selesai |
| Auth + RBAC (Backend) | ✅ Selesai |
| Users CRUD (Backend) | ✅ Selesai |
| Task Module (CRUD + state machine status) di Backend | ✅ Selesai |
| Task Checklist di Backend | ✅ Selesai — validasi kelengkapan bukti wajib sebelum submit sudah ditegakkan |
| Endpoint Evidence (photo/receipt) di Backend | ✅ Selesai — sekarang punya Task_SPPD nyata untuk direferensikan |
| Design Tokens (Mobile + Web) | ✅ Selesai |
| Migrasi SQLite + Dependency Injection (Mobile) | ✅ Selesai |
| Geotagged Camera Engine | ✅ Selesai (kode + DI) |
| Sync Queue (offline outbox) | ✅ Selesai — SELURUH jenis entity (foto, nota, checklist) sudah tersambung end-to-end |
| OCR Receipt Scanner | ✅ Selesai (kode + `ReceiptScannerEntryPage`), tombol "Scan Nota" di Task Detail sudah tersambung |
| Task Detail (checklist, header, evidence actions) di Mobile | ✅ Selesai (kode + DI) |
| Auth (Login) di Mobile | ✅ Selesai — `POST /auth/login` + token & profil tersimpan di `flutter_secure_storage` |
| Beranda di Mobile | ✅ Selesai — Bagian 11.1: header, kartu tugas aktif, aksi cepat, status sync |
| Flow Login → Beranda → Detail Tugas | ✅ Selesai — `main.dart` memakai `_AuthGate` |
| RootDetector native (Android) | ✅ Selesai — heuristik sederhana (build tags, binary `su`, aplikasi manajemen root) |
| RootDetector native (iOS) | ❌ Belum dibangun — fail-safe ke `false` |
| LPJ Generator (Backend) | ✅ Selesai — `POST /lpj/generate`, generate PDF on-demand dari tugas VERIFIED |
| LPJ Generator (halaman Web/Mobile) | ❌ Belum dibangun — belum ada UI untuk memicu endpoint ini |
| Web Dashboard (halaman nyata) | ❌ Belum dibangun — baru token |

**PENTING - migrasi database baru diperlukan:** `schema.prisma` baru saja ditambahkan model `Task_Checklist_Item`. Jika Anda sudah pernah menjalankan `prisma migrate dev` sebelumnya, jalankan lagi:
```bash
npx prisma migrate dev --name add_task_checklist
```

**Catatan soal role:** dokumen spesifikasi produk (`docs/tulap_product_spec.md`) sudah disederhanakan menjadi 4 role, konsisten dengan skema Prisma (`schema.prisma`): PEGAWAI, VERIFIKATOR, ADMIN, SUPER_ADMIN. Tanggung jawab BENDAHARA (verifikasi nominal/keuangan) digabung ke VERIFIKATOR; tanggung jawab PIMPINAN (dashboard ringkas read-only) digabung ke ADMIN.

**Catatan penting soal DI kamera:** jangan navigasi langsung ke `GeotagCameraPage`/`ReceiptScannerPage` — selalu lewat `GeotagCameraEntryPage`/`ReceiptScannerEntryPage`. `TaskDetailPage` dan `HomePage` sudah memanggil keduanya dengan benar lewat tombol "Foto Kegiatan"/"Scan Nota".

**Catatan soal Quick Actions di Beranda:** tombol "Lokasi" dan "Lihat LPJ" pada Aksi Cepat Beranda masih placeholder (menampilkan snackbar "belum tersedia") — belum ada layar Peta atau LPJ di sisi mobile (di luar cakupan pekerjaan ini, lihat saran fitur tambahan).

---

*Dokumen referensi desain lengkap ada di `docs/tulap_product_spec.md` — gunakan ini sebagai acuan setiap kali membangun fitur baru.*
