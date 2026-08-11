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
  @aws-sdk/client-s3 @nestjs/platform-express multer
npm install -D prisma @types/passport-jwt @types/bcrypt @types/multer
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

**Catatan:** hanya modul `auth` (login, register, RBAC) yang sudah dibangun. Modul `users`, `tasks`, `evidence` (photo/receipt), `finance`, dan `documents` (LPJ) masih perlu dibangun menyusul.

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

**Sebelum aplikasi bisa di-run**, satu hal ini masih perlu dilengkapi:
1. **RootDetector native implementation** — saat ini hanya wrapper `MethodChannel` kosong; perlu kode native Kotlin/Swift, atau ganti dengan package siap pakai (`safe_device`).
2. **Session DI untuk ReceiptScannerPage** — pola yang sama seperti `GeotagCameraEntryPage` perlu dibuat untuk fitur OCR sebelum bisa dipanggil dari UI.
3. **Flow Login → Beranda** — `main.dart` saat ini masih mengarah ke halaman placeholder; perlu dihubungkan ke fitur Auth & Beranda begitu keduanya dibangun di sisi mobile.

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
| OCR Receipt Scanner | ✅ Selesai (kode), ⚠️ belum ada entry page DI khusus scanner |
| Task Detail (checklist, header, evidence actions) di Mobile | ✅ Selesai (kode + DI) |
| LPJ Generator | ❌ Belum dibangun |
| Web Dashboard (halaman nyata) | ❌ Belum dibangun — baru token |

**PENTING - migrasi database baru diperlukan:** `schema.prisma` baru saja ditambahkan model `Task_Checklist_Item`. Jika Anda sudah pernah menjalankan `prisma migrate dev` sebelumnya, jalankan lagi:
```bash
npx prisma migrate dev --name add_task_checklist
```

**Catatan penting soal role:** dokumen spesifikasi produk (`docs/tulap_product_spec.md`, Bagian 6) menyebut 6 role (termasuk BENDAHARA & PIMPINAN), namun skema Prisma (`schema.prisma`) baru mendukung 4 role (PEGAWAI, VERIFIKATOR, ADMIN, SUPER_ADMIN). Ini kesenjangan yang perlu diputuskan: tambahkan 2 role tsb ke enum `RoleName` + jalankan migrasi, atau perbarui dokumen spesifikasi agar konsisten dengan implementasi.

**Catatan penting soal DI kamera:** jangan navigasi langsung ke `GeotagCameraPage` — selalu lewat `GeotagCameraEntryPage`. `TaskDetailPage` sudah memanggil ini dengan benar lewat tombol "Foto Kegiatan". Tombol "Scan Nota" di `TaskDetailPage` MASIH placeholder (menampilkan snackbar) karena pola `GeotagCameraEntryPage` belum direplikasi untuk `ReceiptScannerPage` — ini pekerjaan berikutnya yang paling jelas di sisi mobile.

---

*Dokumen referensi desain lengkap ada di `docs/tulap_product_spec.md` — gunakan ini sebagai acuan setiap kali membangun fitur baru.*
