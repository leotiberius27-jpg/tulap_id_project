# TURLAP.ID — Audit Sistem Existing

**Tanggal audit:** 2026-10-13
**Branch:** `main` (HEAD `ad74e6c`, 110 commit)
**Metode:** pembacaan kode, pemeriksaan konfigurasi, dan baseline test/static analysis non-destruktif. Tidak ada kode sumber yang diubah, tidak ada migrasi atau koneksi ke database/production.

> **Cara membaca status**
> - **COMPLETE**: diimplementasikan **dan** ada bukti verifikasi (test lulus atau verifikasi perangkat yang tercatat).
> - **PARTIAL**: sebagian diimplementasikan, atau diimplementasikan tetapi belum memenuhi target.
> - **BROKEN**: terbukti bermasalah dari pembacaan kode (jalur eksekusi jelas) atau dari test.
> - **MISSING**: belum ada.
> - **UNKNOWN**: belum dapat dipastikan tanpa pengujian runtime/production.
>
> Label **[KODE]** berarti temuan dari membaca kode. Label **[TEST]** berarti dari test yang dijalankan saat audit ini. Label **[CATATAN-SESI]** berarti dari verifikasi perangkat pada sesi sebelumnya yang tercatat, bukan diulang hari ini.

---

## 1. Executive Summary

TURLAP.ID (di kode bernama **Tulap.id**) sudah berupa **monorepo tiga aplikasi** yang berfungsi:

| Aplikasi | Stack | Skala |
|---|---|---|
| `tulap_backend/` | NestJS 10 + Prisma 5 + PostgreSQL + S3 (MinIO) | 14 modul domain + 5 adapter infrastruktur, ±10.000 baris TS, 8 migrasi |
| `tulap_mobile/` | Flutter (Dart SDK ^3.12) | 21 fitur, 449 file Dart, 51 file test |
| `tulap_web/` | Next.js 16.3 (App Router) + React 19 + Tailwind 3 | 6 halaman dashboard, 17 route handler |

Kondisi umumnya:

- **Android sudah sangat kaya**, bahkan berlebih dibanding target "Field Operations". Ada kamera geotag, watermark, OCR nota, outbox SQLite, Sync Center, dan deteksi mock/root. Selain itu ada juga Travel Mission/SPPD, paket LPJ, pembuat PDF laporan, dashboard analitik, pencarian arsip, asisten "Tanya Tulap", dan langganan berbayar (Midtrans).
- **Web masih tipis.** Isinya login, daftar tugas, detail tugas dengan preview bukti, tombol Approve/Revisi/Tolak, buat tugas, kelola pegawai, notifikasi, dan unduh PDF LPJ. Belum ada File Explorer/Drive, audit log viewer, verifikasi per-nota, koreksi OCR, monitoring sync, atau manajemen perangkat.
- **Backend sudah menjadi pusat** (JWT global guard, RBAC 4 role, audit log append-only, rate limit), tetapi ada **celah keamanan dan integritas yang serius**:
  1. **IDOR di endpoint laporan** `/lpj/report/*`. Setiap user yang login dapat membaca, mengunggah, dan "menghapus" laporan tugas siapa pun. Laporan ini juga disimpan *di dalam tabel Audit_Log* sebagai metadata.
  2. **Bucket penyimpanan bukti bersifat publik** (anonymous read). Foto, nota, dan PDF LPJ dapat diunduh siapa saja yang memegang URL.
  3. **Tidak ada isolasi organisasi/instansi.** Semua VERIFIKATOR/ADMIN melihat dan dapat memproses tugas dan pegawai dari semua instansi.
  4. **Web membuat sesi ADMIN palsu** ("demo") bila backend tidak dapat dihubungi.
  5. **Hash mismatch tidak menolak upload** dan hasilnya tidak disimpan. Kolom `integrityHash` menyimpan klaim klien, bukan hash hitungan server.
  6. **Item sync yang terputus saat status `uploading` macet permanen.** Item tidak diulang otomatis dan tidak punya tombol "Coba Lagi".
  7. **Refresh token tidak dapat dicabut.** Tidak ada tabel sesi/perangkat, dan logout tidak mencabut token.
- **Metadata bukti banyak yang dibuang server.** Akurasi GPS, hash asli, waktu perangkat, tipe media (foto/video), altitude/heading, dan field nota (subtotal, pajak, nomor nota, metode bayar) dikirim mobile tetapi tidak punya kolom di Prisma.
- **Ada tiga jalur LPJ yang tidak terintegrasi**: PDF backend per-tugas, PDF mobile "laporan kegiatan", dan "LPJ Package" Travel Mission.

**Kesimpulan:** fondasinya layak dipertahankan (stack, modular monolith, outbox mobile, audit log). Prioritas pertama bukan fitur baru, melainkan **menutup celah P0 keamanan dan integritas data**. Setelah itu baru memperkaya model Evidence dan memindahkan fungsi manajemen ke web.

---

## 2. Current Technology Stack

| Lapisan | Teknologi (terverifikasi dari manifest) | Sumber |
|---|---|---|
| Backend framework | NestJS 10.4, Express, class-validator (whitelist + forbidNonWhitelisted) | `tulap_backend/package.json`, `src/main.ts` |
| ORM / DB | Prisma 5.19, PostgreSQL 16 (docker) | `prisma/schema.prisma`, `docker-compose.prod.yml` |
| Auth | `@nestjs/jwt` + passport-jwt, bcrypt, Google/Apple/Facebook verifier, Firebase Admin (login via Firebase ID token) | `src/modules/auth/*` |
| Storage | `@aws-sdk/client-s3` ke MinIO (S3-compatible), URL publik via Caddy | `src/infrastructure/storage/s3-storage.service.ts`, `docs/MINIO_SETUP_GUIDE.md` |
| Push | firebase-admin FCM | `src/infrastructure/push/` |
| Mirror tambahan | Cloud Firestore (cermin satu arah, no-op jika tidak dikonfigurasi) | `src/infrastructure/firestore/firestore-sync.service.ts` |
| PDF | pdfkit (backend), `pdf` + `printing` (mobile) | `lpj.service.ts`, `pdf_report_generator.dart` |
| Email | nodemailer (OTP lupa sandi) | `src/infrastructure/mailer/` |
| Pembayaran | Midtrans (QRIS/VA) via adapter | `src/modules/payments/` |
| Rate limit | `@nestjs/throttler` global 100/menit, login 5/menit | `app.module.ts`, `auth.controller.ts` |
| Mobile | Flutter, provider + get_it (DI), dartz (Either), dio, sqflite, flutter_secure_storage | `tulap_mobile/pubspec.yaml` |
| Kamera/GPS | `camera` 0.12, `image_picker`, `geolocator` 13, sensors_plus, `LocationFusionEngine` (Kalman, belum di-commit) | `lib/core/geo/` |
| OCR | Google ML Kit Text Recognition (on-device) + `image` untuk preprocessing | `lib/core/ocr/` |
| Peta | google_maps_flutter (API key; billing GCP nonaktif per 2026-09-21 [CATATAN-SESI]) | `features/home/.../location_distribution_map_page.dart` |
| Web | Next.js 16.3.1, React 19.2, Tailwind 3, lucide-react; tidak ada state library atau test | `tulap_web/package.json` |
| CI | GitHub Actions: backend (`prisma generate`, typecheck, build, **tanpa test**), mobile (analyze + test). **Web tidak punya CI.** | `.github/workflows/` |
| E2E | `e2e/` (untracked), scaffold `@e2e-dev/web` dengan 1 test "app opens" | `e2e/tests/example.e2e.ts` |
| Deployment | Dockerfile backend + `docker-compose.prod.yml` (Postgres + API), MinIO terpisah + Caddy HTTPS | `tulap_backend/`, `docs/MINIO_SETUP_GUIDE.md`, `RUNBOOK.md` |

---

## 3. Repository Structure

```
tulap_id_project/
├── .github/workflows/        backend-ci.yml, mobile-ci.yml
├── docs/                     product spec, MinIO guide, legal, play-store listing
├── Referensi/                aset desain referensi (png/mp4)
├── RUNBOOK.md                panduan operasional dev → rilis
├── e2e/                      (untracked) scaffold e2e web
├── tulap_backend/
│   ├── prisma/               schema.prisma (718 baris), 8 migrations, seed.ts, seed-dummy.ts
│   └── src/
│       ├── common/           guards (JwtAuthGuard, RolesGuard), decorators
│       ├── infrastructure/   prisma, storage(S3), mailer, push(FCM), firestore
│       └── modules/          auth, users, tasks, checklist, evidence, lpj, audit,
│                             notifications, travel, search, dashboard, assistant,
│                             subscriptions, payments
├── tulap_mobile/
│   ├── lib/app/              DI (injection_container.dart), main_shell
│   ├── lib/core/             camera, database(SQLite), geo, imaging(watermark), ocr,
│   │                         network(dio), security, sync, session, theme, widgets
│   ├── lib/features/         21 fitur (lihat §5)
│   └── test/                 51 file test
└── tulap_web/
    └── src/
        ├── app/(dashboard)/  tasks, tasks/[id], tasks/new, employees, employees/new
        ├── app/api/          BFF route handlers (auth, tasks, employees, lpj, notifications)
        ├── components/       verification-actions, generate-lpj-button, dll.
        └── lib/              api.ts (apiFetch), session.ts (cookie httpOnly), types.ts
```

**Git status saat audit**, berisi pekerjaan lokal yang belum di-commit dan **tidak boleh ditimpa**:

| File | Status | Keterangan |
|---|---|---|
| `tulap_mobile/lib/core/geo/fast_location_service.dart` | M (+/-927) | Rewrite di atas Kalman fusion engine |
| `tulap_mobile/lib/core/geo/location_fusion_engine.dart` | ?? | Engine baru, 8 unit test |
| `tulap_mobile/lib/features/quick_geotag/` | ?? | Halaman "Foto + Kunci GPS" |
| `tulap_mobile/lib/features/account/.../account_page.dart`, `logout_protection_dialog.dart` | M | Menu Quick Geotag dan dialog logout |
| `tulap_mobile/lib/features/task_detail/.../task_detail_controller.dart` | M | Tidak lagi memanggil `stopWarmUp` |
| `tulap_mobile/test/core/`, `test/features/account/`, `test/features/quick_geotag/` | ?? | Test baru |
| `e2e/` | ?? | Scaffold e2e |
| `git stash` | — | "backup: redesain TURLAP + paket geo luar (dihapus 2026-10-13)". **Jangan di-apply tanpa izin.** |

---

## 4. Existing Features Inventory (lintas aplikasi)

| # | Kapabilitas | Mobile | Backend | Web | Status keseluruhan |
|---|---|---|---|---|---|
| 1 | Login email/sandi | ✔ | ✔ | ✔ | COMPLETE [CATATAN-SESI 2026-08-22/23] |
| 2 | Google / Apple / Facebook / Firebase login | ✔ | ✔ | Google, Apple | PARTIAL (Apple belum diverifikasi di iOS nyata) |
| 3 | Self-registration, OTP reset sandi | ✔ | ✔ | reset saja | COMPLETE [CATATAN-SESI] |
| 4 | Daftar & detail tugas | ✔ | ✔ | ✔ | COMPLETE |
| 5 | Buat tugas (penugasan) | kegiatan mandiri | ✔ | ✔ | COMPLETE |
| 6 | Checklist tugas | ✔ | ✔ | ✔ (lihat/tambah) | COMPLETE |
| 7 | Kamera geotag + watermark | ✔ | ✔ (upload) | preview | PARTIAL: metadata hilang di server (§8) |
| 8 | Video bukti | ✔ | ✔ (disimpan di `Geotag_Photo`) | tampil sebagai `<img>` | PARTIAL: tipe media tidak disimpan |
| 9 | Scan nota + OCR on-device | ✔ | ✔ (upload) | preview | PARTIAL: field nota terbuang, belum ada koreksi di web |
| 10 | Offline outbox + background sync | ✔ | — | — | PARTIAL / **BROKEN** untuk item `uploading` (§10) |
| 11 | Sync Center | ✔ | — | — | PARTIAL |
| 12 | Verifikasi tugas (approve/revisi/tolak + catatan) | — | ✔ | ✔ | COMPLETE di level **tugas** |
| 13 | Verifikasi per-bukti / per-nota | — | kolom ada, **tidak pernah ditulis** | — | MISSING |
| 14 | LPJ PDF per-tugas | — | ✔ (on-the-fly, tidak disimpan) | ✔ (unduh) | PARTIAL |
| 15 | Laporan kegiatan PDF (mobile) | ✔ | disimpan di `Audit_Log.metadata` | — | **BROKEN** (keamanan, §9) |
| 16 | Travel Mission / SPPD / LPJ Package | ✔ | ✔ | — | PARTIAL (mobile-only UI) |
| 17 | Audit trail | — | ✔ append-only | — (tidak ada viewer) | PARTIAL |
| 18 | Notifikasi in-app + FCM push | ✔ | ✔ | ✔ (bell) | PARTIAL (push belum diverifikasi end-to-end) |
| 19 | Pencarian arsip | ✔ | ✔ | filter dasar | PARTIAL |
| 20 | Dashboard analitik | ✔ | ✔ | daftar tugas saja | PARTIAL |
| 21 | Asisten "Tanya Tulap" | ✔ | ✔ | — | PARTIAL: **rule/keyword-based, bukan LLM** |
| 22 | Langganan + Midtrans QRIS/VA | ✔ | ✔ | — | UNKNOWN (sandbox; belum diverifikasi live) |
| 23 | Manajemen pegawai | — | ✔ | ✔ | COMPLETE |
| 24 | Manajemen perangkat / sesi | — | hanya `DeviceToken` FCM | — | MISSING |
| 25 | File Explorer / Drive | — | — | — | MISSING |
| 26 | Peta sebaran lokasi | ✔ | — | — | **BROKEN** di device (billing Maps nonaktif, bukan bug kode) [CATATAN-SESI] |
| 27 | Quick Geotag (Foto + Kunci GPS) | ✔ lokal saja | — | — | PARTIAL (uncommitted, tidak sync) |

---

## 5. Mobile Feature Inventory

Root: `tulap_mobile/lib/features/`. Arsitektur: Clean Architecture per fitur (data/domain/presentation), DI melalui `lib/app/di/injection_container.dart`.

| Fitur | Layar utama | Fungsi | Status | Klasifikasi target |
|---|---|---|---|---|
| `auth` | welcome, login, register, forgot_password | Email, Google, Apple, Facebook, Firebase, biometrik | COMPLETE | KEEP |
| `home` | home_page, location_distribution_map_page, location_activity_detail_page | Beranda, kategori, peta sebaran | PARTIAL (peta butuh billing) | KEEP (sederhanakan) |
| `task_list`, `history` | task_list_page, history_page | Daftar tugas, riwayat | COMPLETE | KEEP |
| `task_detail` | task_detail_page, create_activity_page | Detail, checklist, start/submit, kegiatan mandiri | COMPLETE | KEEP. Buat kegiatan mandiri: REVIEW |
| `geotag_camera` | geotag_camera_page (+16 widget) | Kamera, GPS, watermark, template, video | PARTIAL (preview CameraX bermasalah di Unisoc [CATATAN-SESI]) | KEEP |
| `quick_geotag` | quick_geotag_page | Foto via intent + kunci GPS | PARTIAL, lokal saja | KEEP → INTEGRATE ke outbox |
| `expense_ocr` | receipt_scanner, manual_expense, receipt_detail, activity_expenses | OCR ML Kit, parser, koreksi manual | PARTIAL (belum diverifikasi device setelah fix 2026-09-21) | KEEP |
| `sync_queue` | sync_center_page | Outbox, status, retry manual | PARTIAL/BROKEN (§10) | KEEP + IMPROVE |
| `evidence_gallery` | activity_gallery, evidence_viewer | Galeri bukti tugas | COMPLETE | KEEP |
| `evidence_verification` | evidence_detail, evidence_verification, technical_details | Cek integritas lokal (re-hash). **Bukan** keputusan verifikator | COMPLETE | KEEP (ganti label agar tidak rancu dengan verifikasi web) |
| `notifications` | notifications_page, settings | Notifikasi in-app + FCM | PARTIAL | KEEP |
| `account` | 14 halaman (profil, keamanan, kamera, lokasi, penyimpanan, dll.) | Profil, preferensi, logout protection | COMPLETE | KEEP (sederhanakan) |
| `activity_report` | report_draft_review, report_preview, task_reports_list | Generate PDF laporan di device, unggah ke `/lpj/report/upload` | PARTIAL + backend BROKEN | MOVE_TO_WEB (generate), KEEP (lihat) |
| `lpj` | lpj_summary_page (644 baris) | Ringkasan anggaran vs realisasi | PARTIAL | MOVE_TO_WEB |
| `travel_mission` | 5 halaman (create, list, detail, lpj review/generate, package preview) | SPPD, dokumen pendukung, paket LPJ | PARTIAL | MOVE_TO_WEB (administrasi), KEEP (lihat & unggah dokumen dari lapangan) |
| `dashboard` | (service + widget di home) | Analitik personal | PARTIAL | MOVE_TO_WEB (analitik), KEEP ringkasan sederhana |
| `search_archive` | widget di home | Pencarian lintas entitas | PARTIAL | REVIEW → web |
| `assistant` | tanya_tulap_page | Intent router berbasis keyword | PARTIAL | REVIEW / DEPRECATE (butuh keputusan) |
| `subscription` | 6 halaman pembayaran | Paket GRATIS/BASIC/PRO/PRO_PLUS, Midtrans | UNKNOWN | REVIEW (model bisnis B2G vs personal, butuh keputusan) |
| `location` | location_page | Halaman lokasi | UNKNOWN | REVIEW |

**Penyimpanan lokal** (`lib/core/database/local_database.dart`, 882 baris): 15 tabel SQLite (`geotag_photos`, `expense_notes`, `sync_queue`, `tasks`, `task_checklist_items`, `activity_*`, `notifications`, `travel_missions`, `supporting_documents`, `lpj_packages`, `search_index`, `recent_searches`, `security_events`) dengan migrasi `onUpgrade` aditif (ALTER TABLE ADD COLUMN). Ini sudah praktik yang aman.

**Folder kosong:** `lib/screens/`, `lib/widgets/`. Ini sisa struktur lama yang tidak berisi file.

**Dependensi terdaftar tapi tidak dipakai:** `cloud_firestore` (grep `FirebaseFirestore` di `lib/` tidak menemukan hasil) [KODE].

---

## 6. Web Feature Inventory

Root: `tulap_web/src/`. Pola **BFF**: browser hanya bicara ke `/api/*` (Route Handler Next.js). Route handler membaca token dari cookie httpOnly lalu memanggil backend (`lib/api.ts`). Pola ini bagus dan layak dipertahankan.

| Halaman / komponen | Fungsi | Status |
|---|---|---|
| `/login` + `social-login-buttons`, `forgot-password-modal` | Email, Google, Apple, OTP reset; PEGAWAI ditolak masuk | COMPLETE [CATATAN-SESI 2026-08-23] |
| `/tasks` (Dashboard) | Daftar tugas, filter status via query string | PARTIAL (belum ada pagination UI, belum ada pencarian penuh) |
| `/tasks/[id]` | Detail, checklist, **preview foto & nota**, flag mock/root, `verification-actions` (approve/revisi/tolak), `generate-lpj-button` | PARTIAL: tidak menampilkan hash, akurasi GPS, waktu perangkat, OCR raw, maupun riwayat keputusan |
| `/tasks/new` + `create-task-form` | Buat penugasan + checklist | COMPLETE |
| `/employees`, `/employees/new`, `employee-actions` | CRUD pegawai, nonaktif/aktifkan | COMPLETE |
| `notification-bell` | Notifikasi | COMPLETE |
| Sidebar: "Pengaturan" | `href: '#'` | MISSING (placeholder) |
| Middleware | Cek **keberadaan** cookie access token untuk `/tasks`, `/employees` | PARTIAL: tidak ada refresh token flow, jadi sesi efektif hanya 15 menit |

**Belum ada di web:** File Explorer/Drive, All Evidence/Photos/Receipts/Documents, LPJ arsip/versi, audit log viewer, verifikasi per-nota, koreksi OCR, manajemen pengeluaran, Travel Mission/SPPD, monitoring sync, manajemen perangkat, analitik, pengaturan.

**Temuan web kritis:**
- `src/app/api/auth/login/route.ts:52-68`, juga `google/route.ts` dan `apple/route.ts`: blok `catch` membuat **sesi ADMIN "demo"** (`demo_web_access_token`) untuk email apa pun bila backend tidak dapat dihubungi [KODE]. Backend menolak token palsu itu, sehingga data tidak bocor. Namun UI admin tetap dirender untuk orang yang tidak terautentikasi, dan perilaku ini menyesatkan saat outage production.
- Refresh token disimpan di cookie tetapi **tidak pernah dipakai** (grep `refresh` di `src/` hanya menemukan penulisan) [KODE].

---

## 7. Backend/API Inventory

Semua endpoint di belakang `JwtAuthGuard` global, kecuali yang diberi `@Public()`. `RolesGuard` mengevaluasi `@Roles()`. `ThrottlerGuard` diterapkan global.

| Modul | Endpoint utama | Pemakai | Status | Catatan |
|---|---|---|---|---|
| auth | `POST /auth/login, refresh, register(ADMIN), register-self, forgot-password, reset-password, google, apple, facebook, firebase-login`, `GET /auth/profile` | M, W | COMPLETE | Refresh stateless, tidak ada rotasi/revoke |
| users | `GET/PATCH /users/me`, `POST/DELETE /users/me/photo`, `GET /users`, `GET/PATCH/DELETE /users/:id`, `POST /users/:id/reactivate` | M, W | COMPLETE | Tidak ada scoping instansi |
| tasks | `POST /tasks`, `POST /tasks/self`, `GET /tasks`, `GET /tasks/:id`, `GET /tasks/:id/evidence`, `PATCH /tasks/:id`, `POST /tasks/:id/{start,submit,resubmit,approve,request-revision,reject,complete}` | M, W | COMPLETE | State machine `ALLOWED_TRANSITIONS` (`tasks.service.ts:21-40`). Tidak ada scoping instansi untuk VERIFIKATOR/ADMIN |
| checklist | `GET/POST /tasks/:id/checklist`, `PATCH .../:itemId` | M, W | COMPLETE | Ownership dicek |
| evidence | `POST /evidence/photo`, `POST /evidence/receipt`, `GET/DELETE /evidence/photo/:id`, `GET /evidence/photo/:id/verify`, `GET/DELETE /evidence/receipt/:id` | M | PARTIAL | Lihat §8 dan §9 |
| lpj | `POST /lpj/generate` (PDF stream), `POST /lpj/report/upload`, `GET /lpj/report/task/:taskId`, `GET/DELETE /lpj/report/:id` | W, M | **BROKEN** | Endpoint `report/*` tanpa otorisasi kepemilikan dan disimpan di Audit_Log |
| audit | `GET /audit-logs` (ADMIN), `POST /audit-logs/security-event` | M | COMPLETE | Tidak ada viewer web |
| notifications | `GET`, `PATCH :id/read`, `PATCH read-all`, `POST/DELETE device-token` | M, W | COMPLETE | Ownership dicek |
| travel | CRUD `/travel`, `/travel/document`, `/travel/lpj` | M | PARTIAL | Ownership per-user dicek; tidak ada akses verifikator/admin |
| search | `GET /search` | M | PARTIAL | — |
| dashboard | `GET /dashboard` | M | PARTIAL | — |
| assistant | `POST /assistant/query` | M | PARTIAL | Keyword-based, cabang "LLM" adalah stub |
| subscriptions / payments | `/subscriptions/me`, `select-free`, `/payments/checkout`, `/payments`, `/webhooks/midtrans` | M | UNKNOWN | Idempotency checkout dan dedupe webhook sudah ada di skema |

**Arsitektur backend:** modular monolith yang rapi. Infrastruktur (S3, mailer, push, Firestore) terisolasi di `src/infrastructure`. **Rekomendasi: pertahankan, tanpa microservices.**

**Belum ada:** background worker/queue (semua proses sinkron dalam request), endpoint presigned URL, endpoint register/finalize evidence, model Organization, model Device/Session, endpoint verifikasi per-bukti.

---

## 8. Database Inventory

Sumber: `tulap_backend/prisma/schema.prisma` dan 8 migrasi (`20260812073040_init` … `20260920070000_sync_travel_mission_and_user_oauth_fields`).

| Model | Tujuan | Catatan audit |
|---|---|---|
| `Role`, `User` | RBAC 4 role | `instansiName`/`unitKerja` berupa **string bebas**, bukan relasi organisasi |
| `Task_SPPD` | Tugas | State machine 7 status, `budgetAmount`/`realizedAmount` |
| `Task_Checklist_Item` | Checklist | OK |
| `Geotag_Photo` | Foto **dan video** | **Tidak ada**: `gpsAccuracy`, `gpsProvider`, `fixTimestamp`, `deviceTimestamp`, `deviceId`, `mimeType`, `mediaType`, `fileSize`, `originalHash`, `serverComputedHash`, `hashVerified`, `clientEvidenceId`, `verificationStatus`, URL original terpisah dari watermark |
| `Expense_Note` | Nota | Kolom verifikasi (`verifierId`, `verifiedAt`, `rejectionReason`) **tidak pernah ditulis** oleh endpoint mana pun [KODE: grep `verifierId`]. Tidak ada subtotal, pajak, nomor nota, metode bayar, hash, maupun kategori `ATK`/`PERLENGKAPAN` (dipetakan ke `LAINNYA`) |
| `Audit_Log` | Jejak audit append-only | **Disalahgunakan** sebagai penyimpanan laporan kegiatan (`entity='Activity_Report'`) |
| `Notification`, `DeviceToken` | Notifikasi, token FCM | `DeviceToken` bukan registrasi perangkat yang sebenarnya |
| `Task_Revision_Note` | Riwayat catatan revisi/tolak | Baik, menjadi dasar riwayat verifikasi |
| `Travel_Mission`, `Supporting_Document`, `LPJ_Package` | SPPD dan paket LPJ | `organizationId` berupa string tanpa relasi; `LPJ_Package` sudah ber-versi dan ber-hash |
| `Subscription`, `PaymentTransaction`, `Processed_Webhook_Event` | Billing | Idempotency key dan dedupe webhook sudah ada |

**Tidak ada:** `Organization`, `Device`/`Session`, `Evidence` generik (atau `Evidence_File` original/preview), `Verification_Decision` per-bukti, `Folder`/`Document`, `Activity_Report` (laporan mobile).

**Migrasi:** tidak dapat diverifikasi bebas-drift tanpa database (`prisma migrate diff` membutuhkan shadow DB). Status **UNKNOWN**. Commit `cdcbb4d` menyebut "heal migration/schema drift", jadi drift pernah terjadi.

---

## 9. Authentication & Security Audit

| Area | Temuan | Bukti | Status |
|---|---|---|---|
| Autentikasi API | JWT global guard, "secure by default", user dicek ulang `isActive` di setiap request | `common/guards/jwt-auth.guard.ts`, `strategies/jwt.strategy.ts` | COMPLETE |
| Otorisasi role | `@Roles()` eksplisit; SUPER_ADMIN tidak otomatis lolos | `common/guards/roles.guard.ts` | COMPLETE |
| **IDOR laporan** | `uploadReport` tidak mengecek pemilik tugas. `getTaskReports` dan `getReportById` mengembalikan laporan siapa pun. `deleteReport` menghapus objek S3 milik siapa pun. Semua tanpa `@Roles()` | `modules/lpj/lpj.service.ts:203-330`, `lpj.controller.ts:45-77` | **BROKEN (P0)** |
| **Isolasi organisasi** | VERIFIKATOR/ADMIN melihat dan memproses semua tugas, bukti, dan pegawai semua instansi | `tasks.service.ts:210-226`, `evidence.service.ts:268,344`, `users.service.ts:29-45` | **MISSING (P0 bila multi-instansi)** |
| **Bucket publik** | Bucket production diset anonymous read. URL bukti permanen dan tidak bisa dicabut | `docs/MINIO_SETUP_GUIDE.md:60-69`, `s3-storage.service.ts:89` | **BROKEN (P0, data pribadi/UU PDP)** |
| Bucket listing anonim | Kebijakan `mc anonymous set download` perlu dicek apakah mengizinkan ListBucket | — | UNKNOWN |
| **Sesi demo palsu di web** | Lihat §6 | `tulap_web/src/app/api/auth/{login,google,apple}/route.ts` | **BROKEN (P0)** |
| Refresh token | Stateless 7 hari, tanpa rotasi atau denylist. Logout tidak mencabut. User nonaktif ditolak (baik) | `auth.service.ts:319-363` | PARTIAL |
| Registrasi & pencabutan perangkat | Tidak ada | — | MISSING |
| Penyimpanan token mobile | `flutter_secure_storage` | `core/network/dio_client.dart` | COMPLETE |
| Penyimpanan token web | Cookie httpOnly, `secure` di production, `sameSite=lax` | `tulap_web/src/lib/session.ts` | COMPLETE |
| Rate limiting | Global 100/menit/IP; login 5/menit; forgot 3/menit | `app.module.ts`, `auth.controller.ts` | COMPLETE |
| CORS | `app.enableCors()` tanpa allowlist origin | `src/main.ts:9` | PARTIAL (risiko rendah karena Bearer token) |
| Security headers | Tidak ada helmet | grep `helmet` kosong | MISSING |
| Hapus bukti | PEGAWAI dapat **hard-delete** foto/nota miliknya **kapan pun**, termasuk setelah tugas VERIFIED/COMPLETED. Objek S3 tidak ikut dihapus (orphan) | `evidence.service.ts:279-310, 419-442` | **BROKEN (integritas)** |
| Integritas hash | Server menghitung SHA-256 tetapi **tetap menerima** saat tidak cocok, menyimpan hash klaim klien, dan hasil `hashVerified` hanya masuk metadata audit | `evidence.service.ts:73-110` | **BROKEN (integritas)** |
| Idempotensi upload foto via `dto.id` | Jika `id` milik user lain, respons mengembalikan `photoUrl` milik user lain tanpa cek pemilik (butuh UUID valid) | `evidence.service.ts:44-56` | PARTIAL (risiko rendah) |
| Root detector | Fail-open (`MissingPluginException` dianggap aman) | `core/security/root_detector.dart` | PARTIAL (wajar sebagai indikator, tetapi harus dilaporkan "unknown", bukan "aman") |
| Mock location | Capture **diblokir** saat mock terdeteksi dan event dilaporkan ke `/audit-logs/security-event` | `geotag_camera_repository_impl.dart:130` | COMPLETE (perlu keputusan: blokir vs tandai, §Gap) |
| `ENCRYPTION_KEY` | Ada di `.env.example` tetapi tidak dipakai di kode | grep kosong | MISSING (enkripsi at-rest tingkat aplikasi tidak ada) |
| Secrets di repo | `.env` tidak ter-track (baik). `google-services.json` ter-track (umum untuk Android, bukan secret server) | `git ls-files` | OK |
| `docker-compose.prod.yml` | Postgres mem-publish `5432:5432` ke host. Variabel `POSTGRES_USER/PASSWORD/DB` **kosong** di file | `tulap_backend/docker-compose.prod.yml:7-13` | PARTIAL/UNKNOWN (perlu cek server aktual) |
| Backup & recovery | Tidak ada skrip atau dokumen backup DB/MinIO | — | MISSING |

---

## 10. Offline & Sync Audit

**Yang sudah ada** [KODE]:
- Pola outbox: setiap capture menulis baris `sync_queue` (status `pendingUpload`) setelah data dan file tersimpan lokal (`sync_local_datasource.dart`).
- `BackgroundSyncService` memicu sync saat konektivitas pulih, dengan polling setiap 2 menit dan sekali saat start (`core/sync/background_sync_service.dart`).
- Diproses berurutan (FIFO), dengan auto-retry hingga 5 kali, lalu `failed` dan retry manual di Sync Center.
- 401 (sesi habis) langsung `failed` dengan pesan login ulang (fix 2026-09-21).
- Header `X-Idempotency-Key` dikirim (`sync_remote_datasource.dart:96`), **tetapi backend tidak membacanya**. Idempotensi server memakai `dto.id` (UUID klien) dan `taskId+integrityHash`.
- Timestamp server direkonsiliasi ke baris lokal setelah sukses.
- File lokal tidak dihapus setelah sync (aman, tetapi belum ada kebijakan retensi).

**Masalah:**

| # | Masalah | Bukti | Status |
|---|---|---|---|
| S1 | **Item macet di `uploading`.** Status ini ditulis sebelum upload. Jika app dimatikan atau crash di tengah upload, `ProcessSyncQueue` hanya memilih `pendingUpload`/`waitingForInternet`, dan tombol "Coba Lagi" hanya muncul untuk `failed`. Tidak ada reset saat startup | `process_sync_queue.dart:66-70`, `sync_queue_repository_impl.dart:85-87`, `sync_status_row.dart:93` | **BROKEN** |
| S2 | Tidak ada exponential backoff (polling tetap 2 menit) | `background_sync_service.dart:30` | PARTIAL |
| S3 | Upload langsung multipart ke API (file melewati memori NestJS, batas 100 MB). Tidak ada register → authorize → upload → finalize | `evidence.controller.ts:41-50` | PARTIAL (target belum tercapai) |
| S4 | Retry otomatis Dio setelah refresh token memakai ulang `FormData` yang sudah di-finalize, sehingga kemungkinan besar gagal dan terhitung 1 percobaan | `dio_client.dart:34-40` | UNKNOWN (perilaku Dio; perlu uji) |
| S5 | State yang ada (`pendingUpload, waitingForInternet, uploading, synced, failed`) belum sesuai target (`LOCAL_SAVED…ACTION_REQUIRED`) | `sync_record_entity.dart:24` | PARTIAL |
| S6 | Duplikat nota "identik" (vendor+tanggal+total sama) dalam satu tugas **digabung diam-diam** ke ID lain, sehingga ID lokal ≠ ID server | `evidence.service.ts:174-190` | PARTIAL |
| S7 | Tidak ada pemeriksaan ruang penyimpanan atau kebijakan retensi file lokal | — | MISSING |
| S8 | Quick Geotag tidak masuk outbox | memori sesi 2026-10-13 | PARTIAL |

---

## 11. Existing Test Coverage

> Bagian ini diisi dengan hasil aktual baseline yang dijalankan saat audit (2026-10-13). Lihat juga `docs/implementation/TASK_CHECKLIST.md` §Baseline.

| Aplikasi | Perintah | Hasil aktual [TEST] |
|---|---|---|
| Backend | `npx tsc --noEmit` | ✅ lulus |
| Backend | `npx jest` | ⚠️ 11 suite: **10 lulus, 1 gagal**; 68 test: **67 lulus, 1 gagal**. Gagal: `subscriptions.service.spec.ts:47` ("mengizinkan pembuatan kegiatan jika masih di bawah kuota"). Fixture memakai `currentPeriodEnd: new Date('2026-10-01')` yang sudah lewat, sehingga service memperlakukannya sebagai kedaluwarsa (kuota GRATIS 3) → test "time-bomb", **bukan bug produksi dan bukan regresi**. Peringatan open handle saat teardown |
| Mobile | `flutter analyze --no-fatal-infos` | ✅ **0 error, 0 warning, 243 info** (lint gaya/deprecation). Broken mock dashboard yang tercatat 2026-09-05 sudah tidak ada |
| Mobile | `flutter test` | ✅ **394/394 lulus** (termasuk perubahan uncommitted) |
| Web | `npx tsc --noEmit` | ✅ lulus |
| Web | `npx eslint src` | ⚠️ **2 error** (`status-badge.tsx:6` no-explicit-any, `top-header.tsx:28` set-state-in-effect) + 3 warning unused import |
| Web | test | tidak ada |
| Perangkat fisik / emulator | — | **tidak dijalankan** dalam audit ini |

**Cakupan per area (dari daftar file):**
- Backend: 11 file `*.spec.ts` (auth, tasks, evidence, notifications, search, dashboard, travel, subscriptions, payments, assistant, s3-storage). **Tidak ada** spec untuk `lpj`, `users`, `checklist`, `audit`, dan guard. Backend CI **tidak menjalankan** `npm test`.
- Mobile: 51 file test (unit + widget + beberapa "integration" berbasis fake repository). Tidak ada `integration_test/` di device.
- Web: **0 test**, tanpa CI.
- E2E: 1 smoke test scaffold (untracked).

---

## 12. Technical Debt

1. **Tiga jalur LPJ** yang tidak saling terhubung (`lpj.service.ts` generate, `activity_report` mobile, `travel.service.ts` LPJ_Package).
2. Laporan kegiatan disimpan di `Audit_Log.metadata`, dan `getTaskReports` membaca **semua** log lalu memfilter di memori (`lpj.service.ts:265-281`), sehingga tidak skalabel.
3. DTO menerima field yang lalu dibuang (`UploadPhotoDto` userId/evidenceId/altitude/heading/verificationStatus; `UploadReceiptDto` subtotal/tax/receiptNumber/dll.). Komentar kode mengakui ini (`upload-photo.dto.ts:117-123`).
4. Video disimpan di tabel `Geotag_Photo` tanpa kolom tipe media.
5. Kategori nota di mobile (`atk`, `perlengkapan`) tidak ada di enum server.
6. Tiga sumber "verifikasi" berbeda: integritas lokal (mobile), `verifyEvidencePhoto` (server, dihitung ulang setiap GET dan tidak disimpan), dan status tugas (verifikator).
7. `cloud_firestore` di mobile tidak dipakai. Cermin Firestore di backend adalah sumber kedua yang berpotensi membingungkan.
8. README menyatakan "100% Verified" dan "206 tests", sementara angka aktual berbeda. Klaim dokumentasi perlu diselaraskan.
9. Lint debt mobile (±330 issue info/warning pada 2026-09-05 [CATATAN-SESI]).
10. Log file debug tersebar di repo (`tulap_mobile/*.log`, `tulap_backend/backend.log`). Sudah di-ignore, tetapi masih ada di disk.
11. Folder kosong `lib/screens`, `lib/widgets`.
12. Middleware web hanya cek keberadaan cookie, tanpa refresh flow.

---

## 13. Critical Risks

| ID | Risiko | Dampak | Kemungkinan | Prioritas |
|---|---|---|---|---|
| R1 | IDOR `/lpj/report/*` | Kebocoran dan penghapusan laporan lintas user | Tinggi (cukup login + ID tugas) | **P0** |
| R2 | Bucket bukti publik | Data pribadi/lokasi pegawai terekspos; pelanggaran prinsip UU PDP | Sedang | **P0** |
| R3 | Sesi admin palsu di web saat backend down | UI admin terbuka, kebingungan operasional | Sedang (saat outage) | **P0** |
| R4 | Bukti dapat dihapus setelah diverifikasi | LPJ kehilangan bukti, audit tidak konsisten | Sedang | **P0** |
| R5 | Hash mismatch diterima diam-diam | Bukti termodifikasi lolos tanpa tanda | Rendah–sedang | **P0** |
| R6 | Item sync macet di `uploading` | Bukti tidak pernah sampai ke server tanpa disadari | Sedang (app kill saat upload) | **P0/P1** |
| R7 | Tanpa isolasi instansi | Bocor lintas instansi bila >1 instansi memakai server yang sama | Tergantung model deployment | **P0 jika multi-tenant** |
| R8 | Refresh token tak dapat dicabut | HP hilang berarti akses tetap hidup hingga 7 hari | Sedang | P1 |
| R9 | Tidak ada backup terdokumentasi | Kehilangan data permanen | Rendah, dampak sangat tinggi | P1 |
| R10 | Postgres port 5432 terekspos di compose prod | Serangan brute force ke DB | UNKNOWN (cek firewall server) | P1 |

---

## 14. Features Worth Preserving

- **Struktur modular monolith NestJS** + infrastruktur terisolasi (S3 adapter tunggal).
- **Global guard secure-by-default** + `@Roles()` eksplisit.
- **State machine tugas** (`ALLOWED_TRANSITIONS`) dan endpoint transisi yang sempit.
- **Audit_Log append-only** (setelah laporan dipindah keluar darinya).
- **Task_Revision_Note** sebagai riwayat keputusan.
- **Outbox SQLite + Sync Center** (diperbaiki, bukan diganti).
- **Pemisahan file original vs watermark di mobile** (`originalFilePath` + `originalHash` vs `localFilePath` + `finalHash`, `geotag_camera_local_datasource.dart:74-119`). Konsep ini sudah benar; tinggal diteruskan ke server.
- **Server-authoritative timestamp.**
- **Pola BFF web** dengan cookie httpOnly.
- **LPJ_Package** (versi + SHA-256 + content snapshot) sebagai pola LPJ ber-versi.
- **LocationFusionEngine** (Kalman) dengan unit test.
- **OCR on-device** + parser nota lokal (SPBU, retail) dengan test.
- **Idempotency checkout + dedupe webhook** di payments.

---

## 15. Missing Capabilities

| Kapabilitas target | Status |
|---|---|
| Organization/instansi sebagai entitas + scoping data | MISSING |
| Device registration & revocation, sesi per perangkat | MISSING |
| Model Evidence lengkap (accuracy, provider, fix time, device id, mime, size, original vs preview, flags, status) | MISSING |
| Alur upload register → presigned URL → finalize | MISSING |
| Presigned GET (akses file privat) | MISSING |
| Keputusan verifikasi per-bukti + riwayat | MISSING |
| Koreksi OCR & verifikasi nota di web | MISSING |
| Web Drive (explorer, folder virtual, preview, panel metadata) | MISSING |
| Audit log viewer web | MISSING |
| Monitoring sync (sisi server) | MISSING |
| LPJ terpadu: pilih bukti → tautkan nota ke item → validasi → PDF **dan Word** → versi | PARTIAL (PDF ada, Word tidak ada, versi hanya di Travel) |
| Background worker (OCR server, generate laporan, thumbnail) | MISSING |
| Backup/restore terdokumentasi | MISSING |
| Test web + backend CI menjalankan test | MISSING |
| Template LPJ resmi berdasar regulasi | UNKNOWN (belum ada referensi template yang disetujui di repo) |
