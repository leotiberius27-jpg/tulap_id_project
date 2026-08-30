# Tulap.id — Panduan Arsitektur & Operasional Proyek

Tulap.id adalah solusi digital bagi pegawai lapangan: dokumentasi tugas dinas, bukti foto geotag anti-fake-GPS, pemindaian nota OCR on-device, validasi integritas data, dan sinkronisasi offline-first.

Repository ini berfokus penuh pada **Mobile App (Flutter)** dan **Backend API (NestJS + PostgreSQL)** untuk rilis Play Store & App Store.

Struktur folder:
`
tulap_id_project/
├── docs/
│   └── tulap_product_spec.md      # Spesifikasi Produk & UI/UX Desain
├── tulap_backend/                 # NestJS + Prisma + PostgreSQL + Object Storage
│   ├── prisma/schema.prisma
│   ├── src/
│   ├── Dockerfile
│   ├── docker-compose.prod.yml
│   └── .env.example
└── tulap_mobile/                  # Flutter (Clean Architecture, Feature-First)
    ├── android/
    ├── ios/
    ├── lib/
    ├── test/
    └── pubspec.yaml
`

---

## 1. Backend API (	ulap_backend/)

### Menjalankan di Mode Development:
`ash
cd tulap_backend
npm install
cp .env.example .env
# Sesuaikan DATABASE_URL dan JWT secrets di .env
npx prisma generate
npx prisma migrate dev --name init
npx prisma db seed
npm run start:dev
`

### Menjalankan Automated Unit Tests:
`ash
npm test
`

### Build & Typecheck Produksi:
`ash
npm run typecheck
npm run build
`

### Deployment Produksi dengan Docker:
`ash
docker-compose -f docker-compose.prod.yml up --build -d
`

---

## 2. Mobile Application (	ulap_mobile/)

Aplikasi Flutter Clean Architecture dengan dukungan offline-first (SQLite), deteksi mock location/root/jailbreak, background sync queue, OCR nota on-device, dan biometrik.

### Menjalankan Development:
`ash
cd tulap_mobile
flutter pub get
flutter run
`

### Menjalankan Automated Test Suite:
`ash
flutter test
`
*(Seluruh 206 unit/widget tests teruji dan lolos 100%)*

### Build Rilis Siap Play Store (AAB / APK):
`ash
# App Bundle (Rekomendasi Google Play Console)
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.tulap.id

# Standalone APK
flutter build apk --release --dart-define=API_BASE_URL=https://api.tulap.id
`

---

## 3. Fitur Utama yang Telah Selesai (100% Verified)

| Modul / Fitur | Status | Catatan |
|---|---|---|
| **Database & ORM (Prisma)** | ✅ Selesai | PostgreSQL dengan relasi lengkap Task, Evidence, Checklist, Audit Trail |
| **Auth & RBAC (Backend)** | ✅ Selesai | Dual-token JWT (Access + Refresh), Password Hash, Google & Apple OAuth, Reset OTP |
| **Security & Device Integrity** | ✅ Selesai | Native Root Detection (Android MainActivity.kt) & Native Jailbreak Detection (iOS AppDelegate.swift) |
| **Evidence & Geotag Engine** | ✅ Selesai | Watermark compositing, GPS accuracy validation, SHA-256 integrity hash, S3 storage integration |
| **OCR Receipt Scanner** | ✅ Selesai | On-device ML Kit text recognition, duplicate warning, expense categorization |
| **Offline-First Sync Queue** | ✅ Selesai | SQLite outbox queue, automatic background retry saat online |
| **Activity Workspace & Timeline** | ✅ Selesai | Catatan aktivitas lapangan, status timeline dinamis, galeri bukti foto |
| **Notifikasi & Tema Global** | ✅ Selesai | Notification Center (in-app & API), Dark/Light theme selector |
| **Automated Testing Suite** | ✅ Selesai | 206 Flutter tests + 5 Backend Jest suites (20 tests) pass 100% |
| **Production Ready Build** | ✅ Selesai | Keystore signing, proguard/R8 rules, adaptive app launcher icons |

---
*Dokumen detail spesifikasi ada di [docs/tulap_product_spec.md](docs/tulap_product_spec.md) dan panduan langkah operasional di [RUNBOOK.md](RUNBOOK.md).*
