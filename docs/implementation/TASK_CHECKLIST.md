# TURLAP.ID — Task Checklist

Detail setiap task ada di `IMPLEMENTATION_ROADMAP.md`. Status: `[ ]` belum, `[~]` berjalan, `[x]` selesai + terverifikasi, `[!]` diblokir/menunggu keputusan.

**Status 2026-10-13:** P0-09, P0-01, P0-02, P0-05, P0-03, N-08, P0-06, N-10, P0-07 (sebagian: a, b-evidence, c-web) diimplementasikan di branch `p0/security-hardening` (belum di-commit). Menunggu review sebelum tahap berikutnya.

---

## 0. Baseline (dijalankan 2026-10-13, sebelum perubahan apa pun)

Kondisi working tree saat baseline: ada perubahan mobile yang **belum di-commit** (lihat audit §3). Hasil mobile di bawah ini sudah mencakup perubahan tersebut.

| Aplikasi | Perintah | Hasil aktual |
|---|---|---|
| Backend | `npx tsc --noEmit` | ✅ exit 0 |
| Backend | `npx jest` | ⚠️ **10/11 suite, 67/68 test lulus**. Gagal: `subscriptions.service.spec.ts` › "mengizinkan pembuatan kegiatan jika masih di bawah kuota". Penyebab: fixture `currentPeriodEnd: 2026-10-01` sudah lewat, jadi langganan dianggap kedaluwarsa (kuota GRATIS 3). **Kegagalan existing, bukan regresi** (backend tidak diubah). Ada juga peringatan "worker process failed to exit gracefully" (open handle) |
| Mobile | `flutter analyze --no-fatal-infos` | ✅ 0 error, 0 warning, **243 info** |
| Mobile | `flutter test` | ✅ **394/394 lulus** |
| Web | `npx tsc --noEmit` | ✅ exit 0 |
| Web | `npx eslint src` | ⚠️ **2 error, 3 warning**: `status-badge.tsx:6` no-explicit-any; `top-header.tsx:28` react-hooks/set-state-in-effect; unused imports di `tasks/page.tsx:7`, `login/page.tsx:13`, `task-card.tsx:6` |
| Web | test | — (tidak ada test) |
| E2E | — | tidak dijalankan (scaffold, untracked) |
| Device | — | **tidak dijalankan** di audit ini |

## 0b. Setelah P0-09/P0-01/P0-02 (2026-10-13)

| Aplikasi | Perintah | Sebelum | Sesudah |
|---|---|---|---|
| Backend | `tsc --noEmit` | ✅ | ✅ |
| Backend | `npx jest` | 10/11 suite, 67/68 | **12/12 suite, 102/102** (env lokal **dan** env bersih ala CI) |
| Web | `tsc --noEmit` | ✅ | ✅ |
| Web | `eslint src` | 2 error, 3 warning | 2 error, 3 warning (**identik**, tidak ada temuan baru) |
| Web | `vitest run` | (tidak ada) | **24/24** |
| Mobile | — | 394/394 | tidak dijalankan ulang: tidak ada file mobile yang diubah di tahap ini (checksum WIP identik) |

## 0e. Setelah N-08 (2026-10-13)

| Aplikasi | Perintah | Sebelum | Sesudah |
|---|---|---|---|
| Mobile | `flutter analyze --no-fatal-infos` | 0 error, 0 warning, 243 info | sama, **daftar info identik** |
| Mobile | `flutter test` | 402/402 | **414/414** (+12 baru; 2 test lama diubah) |
| Mobile | perangkat fisik | — | **tidak dijalankan** |
| Backend / Web | — | — | tidak disentuh |

## 0d. Setelah P0-03 (2026-10-13)

| Aplikasi | Perintah | Sebelum | Sesudah |
|---|---|---|---|
| Backend | `tsc --noEmit` | ✅ | ✅ |
| Backend | `npx jest` | 12/12 suite, 102/102 | **13/13 suite, 129/129** (env lokal dan env CI) |
| Web / Mobile | — | — | tidak disentuh di tahap ini |

## 0c. Setelah P0-05 (2026-10-13)

| Aplikasi | Perintah | Sebelum | Sesudah |
|---|---|---|---|
| Mobile | `flutter analyze --no-fatal-infos` | 0 error, 0 warning, 243 info | 0 error, 0 warning, 243 info (**daftar info identik**) |
| Mobile | `flutter test` | 394/394 | **402/402** (+8 test baru) |
| Mobile | perangkat fisik | — | **tidak dijalankan** |

## Prasyarat sebelum task pertama

- [x] Pekerjaan lokal yang belum di-commit **diisolasi tanpa disentuh**. Tidak ada overlap path (WIP hanya di `tulap_mobile/`, `e2e/`). Checksum 35 file WIP identik sebelum/sesudah. Stash tetap utuh. Keputusan nasib WIP tetap di tangan Anda.
- [!] Keputusan D1–D8 (`GAP_ANALYSIS.md` §4). Minimal D1 untuk P0-08 dan D6 untuk P3-04.
- [x] Branch kerja `p0/security-hardening` dibuat dengan `git switch -c` dari `main` (HEAD `ad74e6c`). Working tree tidak berubah, tanpa stash/commit/reset.

---

## P0 — Data integrity, security, critical bugs

- [x] **P0-09** Fixture tanggal tetap diganti periode relatif (`activePeriod()`); `npm test -- --ci` ditambahkan ke `backend-ci.yml`. Bukti: jest 102/102, juga dengan env bersih ala CI. *CI GitHub sendiri belum berjalan (belum di-push).*
- [x] **P0-01** Otorisasi `/lpj/report/*` berbasis `actor` dari JWT. Unggah hanya assignee; baca untuk assignee/SUPER_ADMIN/ADMIN-VERIFIKATOR pembuat tugas atau satu instansi (`instansiName`, sementara); hapus hanya pengunggah; ID bentrok → 409. Bukti: `lpj.service.spec.ts` 34/34 lolos; terhadap kode lama 22/34 gagal. *Belum diuji dari aplikasi mobile/perangkat.*
- [x] **P0-02** Fallback sesi demo dihapus. Backend tidak terjangkau → 503; respons backend 2xx tidak valid/role tak dikenal → 502; tanpa `setSession`. Bukti: `auth-routes.test.ts` (vitest baru) 24/24 lolos; terhadap kode lama 12/24 gagal; uji runtime `next dev` dengan backend mati → 503 tanpa `Set-Cookie`.
- [x] **P0-05** Pemulihan item `uploading` yang tertinggal. Repository mencatat record yang *benar-benar* sedang diproses (in-memory); di awal setiap siklus `ProcessSyncQueue` (start app, koneksi pulih, polling 2 menit, "Kirim Semua"), item `uploading` yang tidak sedang diproses dikembalikan ke retry otomatis. Percobaan yang terputus dihitung, sehingga di batas 5× item menjadi `failed` dengan tombol "Coba Lagi" yang sudah ada. Guard tambahan: record yang sama tidak bisa diproses/di-reset paralel. Bukti: `sync_interrupted_upload_recovery_test.dart` 8/8; tanpa langkah pemulihan 3/8 gagal (status tetap `uploading`); suite penuh 402/402. *Belum diuji di perangkat fisik.* Deviasi dari roadmap: tidak memakai ambang "5 menit" (`lastAttemptAt` tidak diperbarui saat masuk `uploading`, jadi usia item tidak bisa dipercaya) dan tidak menambah tombol baru di baris `uploading` (item pulih otomatis ke status yang sudah punya aksi).
- [x] **P0-03** `DELETE /evidence/photo/:id` & `/evidence/receipt/:id`: hanya pengunggah/pemilik (apa pun role-nya); hanya saat tugas `DRAFT/ONGOING/REVISION_NEEDED`, selain itu 409. Penghapusan atomik (`deleteMany` dengan syarat pemilik + status tugas di query yang sama). Bukti: `evidence-deletion.spec.ts` 27/27; terhadap kode lama 22/27 gagal (16 celah nyata + 6 artefak karena kode lama memakai `delete`, bukan `deleteMany`). Backend 129/129. **Tidak ada klien (mobile/web) yang memanggil endpoint ini**, jadi tidak ada alur yang berubah; pesan error mobile yang direncanakan roadmap tidak diperlukan. Perubahan perilaku disengaja: ADMIN/VERIFIKATOR/SUPER_ADMIN tidak lagi bisa menghapus bukti milik pegawai.
- [ ] **P0-04** Simpan `serverSha256` + `hashVerified` (migrasi aditif) + badge di web
- [x] **P0-06** Cek kepemilikan pada jalur idempotensi `id` dari client di 4 endpoint: `POST /evidence/photo`, `/evidence/receipt` (id milik user lain **atau** tugas lain → 409 tanpa data), `POST /travel/document`, `/travel/lpj` (id milik perjalanan dinas lain → 409; pengecekan dipindah SEBELUM unggah file sehingga retry tidak membuat objek storage yatim baru). `/tasks/self`, `/travel`, `/lpj/report/upload` sudah aman. Bukti: 2 spec baru 11/11; terhadap kode sebelum P0-06 8/11 gagal; backend 140/140 (env lokal + CI).
- [x] **P0-07a** (2026-10-14) `S3StorageService.getSignedReadUrl` / `signStoredUrl` / `keyFromStoredUrl` + dependensi `@aws-sdk/s3-request-presigner@3.1107.0` (versi sama dengan client-s3; lockfile: +1 paket, 0 versi berubah). Ditandatangani untuk host PUBLIK (origin `S3_PUBLIC_URL_BASE`, opsional `S3_SIGNING_ENDPOINT`), TTL 15 menit. `keyFromStoredUrl` longgar (cocokkan `/<bucket>/` di host apa pun, khusus baca); `keyFromUrl` untuk hapus tetap ketat. Verifikasi live MinIO lokal 7/7 (termasuk bucket privat uji sementara: tanpa tanda tangan 403, bertanda tangan 200, signature diubah 403, kedaluwarsa 403).
- [~] **P0-07b** Field aditif `photoSignedUrl`/`scanSignedUrl` SUDAH di: `GET /tasks/:id/evidence`, `GET /evidence/photo/:id`, `GET /evidence/receipt/:id`. BELUM: avatar (`/users/me`, respons login di `auth.service.ts`), `GET /lpj/report/*` (`pdfRemoteUrl`), `GET /travel/:id` (dokumen, paket LPJ, foto/nota tugas), `GET /search` (`thumbnailUrl`, `pdfUrl`), `GET /dashboard` (foto lokasi), respons upload (`photoUrl`/`scanUrl`/`pdfUrl`/`documentUrl` yang disimpan permanen oleh mobile).
- [~] **P0-07c** Web: detail tugas memakai `photoSignedUrl ?? photoUrl` (satu-satunya tempat web memuat file). Mobile: BELUM - butuh persetujuan karena URL bertanda tangan kedaluwarsa dan TIDAK BOLEH disimpan di SQLite/sesi; mobile perlu meminta URL segar saat menampilkan (±11 widget `Image.network`, model `expense_note`, `activity_report`, `lpj_package`, `supporting_document`, `auth_user`, `get_activity_evidence`).
- [!] **P0-07d** Cabut anonymous read bucket production (**butuh persetujuan production**)
- [!] **P0-08** Organization + scoping (menunggu D1)
- [!] **P0-10** Compose prod tanpa publish 5432 (verifikasi server butuh akses dari Anda)

## P1 — Android field capture & reliable sync

- [ ] **P1-01** Kolom metadata Evidence (aditif) + persist field yang dibuang + soft-delete
- [ ] **P1-02** Field nota + kategori `ATK`/`PERLENGKAPAN`
- [ ] **P1-03** State machine sync target + backoff + "Perlu tindakan"
- [ ] **P1-04** Register → presigned PUT → finalize (flag, kompatibel mundur)
- [!] **P1-05** Unggah original + preview (menunggu D7)
- [ ] **P1-06** Device & Session, rotasi refresh, logout, revoke
- [ ] **P1-07** Integrity flags tri-state (perilaku blokir mock menunggu D2)
- [!] **P1-08** Quick Geotag → outbox (menunggu commit WIP)
- [ ] **P1-09** Kebijakan retensi file lokal
- [ ] **P1-10** Refresh token di BFF web
- [!] **P1-11** Backup & restore (eksekusi server butuh akses)
- [ ] **P1-12** helmet + CORS allowlist
- [ ] **P1-13** CI web + perbaiki 2 error ESLint
- [!] **P1-14** Storage: soft-delete, retensi, rekonsiliasi orphan, pembersihan terkontrol (N-09); penghapusan objek menunggu persetujuan

## P2 — Web Drive & Verification

- [ ] **P2-01** `Evidence_Verification` per-bukti + kunci setelah VERIFIED
- [ ] **P2-02** Verification Workspace v2
- [ ] **P2-03** Web Drive (folder virtual berbasis query)
- [ ] **P2-04** Audit log viewer
- [ ] **P2-05** Manajemen perangkat
- [ ] **P2-06** Monitoring sync
- [ ] **P2-07** Edit tugas, pagination, pencarian

## P3 — OCR & LPJ

- [ ] **P3-01** Koreksi & verifikasi per-nota
- [ ] **P3-02** UI Pengeluaran & koreksi OCR web
- [ ] **P3-03** Tabel `Activity_Report` + salin dari Audit_Log (tanpa hapus log)
- [!] **P3-04** LPJ terpadu + PDF + Word + versi (format resmi menunggu D6)
- [ ] **P3-05** Travel/SPPD di web + akses verifikator/admin
- [ ] **P3-06** Sembunyikan layar admin Android di balik flag (setelah syarat MOVE_TO_WEB)

## P4 — Analytics & optimasi

- [ ] **P4-01** Dashboard analitik web
- [!] **P4-02** Tanya Tulap (menunggu D5)
- [!] **P4-03** Firestore mirror + dependensi `cloud_firestore` (menunggu D8)
- [ ] **P4-04** Pembersihan lint Flutter
- [!] **P4-05** Billing Google Maps (akun Anda)
- [ ] **P4-06** Sederhanakan menu Akun
- [ ] **P4-07** Selaraskan README dengan kondisi aktual

## Temuan baru selama P0 (belum ditindaklanjuti, butuh persetujuan)

- [ ] **N-01** Mobile `downloadReportPdf` (`activity_report_remote_datasource.dart:51`) memakai DioClient yang menyisipkan `Authorization: Bearer <JWT>` ke URL absolut **host storage**. Token terkirim ke `storage.tulap.id`, dan MinIO kemungkinan menolak header itu. Dampak runtime UNKNOWN (perlu uji device).
- [ ] **N-02** `deleteReport` hanya menghapus file S3 + mencatat `REPORT_DELETED`. Laporan tetap muncul di `GET /lpj/report/task/:id` (perilaku lama, tidak diubah). Akan selesai di P3-03.
- [ ] **N-03** `POST /lpj/generate` (dipakai web) masih tanpa scoping instansi untuk VERIFIKATOR/ADMIN. Masuk P0-08.
- [ ] **N-04** Record laporan yang mungkin dibuat pihak lain sebelum perbaikan P0-01 tidak dibersihkan (butuh query data production + persetujuan).
- [ ] **N-05** `docker-compose-minio.yml` memakai image `minio:latest` (tidak dipin).
- [ ] **N-06** `DioClient` tidak menetapkan `sendTimeout`. Upload yang koneksinya macet (bukan putus) bisa menggantung lama dan menahan seluruh antrean (`BackgroundSyncService._isSyncing` tetap true) sampai TCP OS menyerah. Upload seperti ini *tidak* dipulihkan P0-05, karena memang masih "sedang berjalan". Masuk P1-03.
- [x] **N-08** Perlindungan file asli Android (2026-10-13). Kebijakan `EvidenceDeletionPolicy`: bukti hanya boleh dihapus bila file ASLI terverifikasi di server. Model data belum punya sinyal itu (yang diunggah hanya watermark; hash server untuk video tidak dicatat), jadi **semua bukti saat ini ditolak dihapus** dengan penjelasan per status (belum terkirim / sedang dikirim / gagal / watermark terkirim tapi asli belum). Bila diblokir, tidak ada file, metadata, atau antrean sync yang disentuh; bila kelak diizinkan, antrean tetap tidak dihapus. Jaring pengaman: `GeotagCameraLocalDataSource.deletePhoto` menolak tanpa `originalVerifiedOnServer: true` (menutup juga `deleteLocalPhoto` yang tak terpakai). Bukti: 12 test baru + 2 test lama diperbarui. *Belum diuji di perangkat.*
- [!] **N-09** Objek MinIO orphan setelah hapus bukti. **Keputusan: jangan hapus objek storage apa pun sekarang.** Didokumentasikan sebagai **P1-14** di roadmap (soft-delete → kebijakan retensi → rekonsiliasi read-only → karantina → pembersihan terkontrol dengan persetujuan per batch).
- [x] **N-10** IDOR baca di asisten "Tanya Tulap" ditutup (2026-10-14). `handleReportAssistance` dan `handleWriteAction` kini memakai aturan akses yang sama dengan handler asisten lain (`canAccessContextTask`): non-privileged hanya tugas yang ditugaskan kepadanya / yang ia buat. Tugas milik orang lain diperlakukan identik dengan tugas yang tidak ada (tanpa oracle keberadaan), dan id yang tidak terverifikasi tidak lagi digemakan ke `sources`/aksi. Bukti: `assistant-context-access.spec.ts` 9/9; terhadap kode lama 3/9 gagal (tepat 3 skenario serangan); backend 149/149 (env lokal + CI). **Catatan:** VERIFIKATOR/ADMIN/SUPER_ADMIN tetap melihat semua instansi di SELURUH asisten (search, total pengeluaran, hitungan, resolve ID) - itu bagian dari P0-08, tidak diubah di sini.
- [ ] **N-11** Backend lain berjalan di port 3000 dari salinan berbeda (`C:/Users/LEO/Downloads/tulap_id_project-main/tulap_backend/dist`), tanpa perbaikan P0. `.env` backend repo ini memakai `S3_PUBLIC_URL_BASE` dengan IP LAN lama (`10.230.74.200`; IP saat ini `10.102.38.200`) - foto yang diunggah saat backend dijalankan tanpa override tersimpan dengan URL yang tidak bisa dimuat HP.
- [ ] **N-07** Pengiriman ulang hasil pemulihan bisa membuat duplikat kecil yang sudah terjadi pada setiap retry hari ini: laporan kegiatan & security event tercatat ganda di Audit_Log, dan dokumen pendukung/LPJ package bisa menyisakan file S3 yatim (file diunggah sebelum cek ID). Foto, nota, kegiatan mandiri, checklist, dan travel mission idempoten di server.
- [ ] **P4-08** Worker antrean (hanya bila perlu)

---

## Log hasil per task

| Tanggal | Task | Perubahan | Test dijalankan | Hasil aktual | Regresi? |
|---|---|---|---|---|---|
| 2026-10-13 | Audit (Fase A/B/C/K) | Hanya dokumen di `docs/` | lihat §0 | lihat §0 | — |
| 2026-10-13 | P0-09 | `subscriptions.service.spec.ts`, `.github/workflows/backend-ci.yml` | `npx jest` (penuh + env CI) | Sebelum 67/68 → sesudah 68/68 (sebelum spec LPJ) | Tidak |
| 2026-10-13 | P0-01 | `lpj.service.ts`, + `lpj.service.spec.ts` | `tsc --noEmit`, `npx jest` | tsc OK; jest 12/12 suite, 102/102 | Tidak (11 suite lain tetap lolos) |
| 2026-10-14 | P0-07 (a, b sebagian, c-web) | `s3-storage.service.ts`, `tasks.service.ts`, `evidence.service.ts`, `evidence.controller.ts`, `tasks.service.spec.ts` (+1 provider), `package.json`/`package-lock.json` backend (+presigner), web `types.ts` + `tasks/[id]/page.tsx`, + `s3-storage-signed-url.spec.ts`, + `evidence-signed-url.spec.ts` | `tsc` BE/web, `jest` (env lokal + CI), `eslint`, `vitest`, verifikasi live MinIO lokal | BE 18/18 suite 168/168; web tsc OK, eslint = baseline, vitest 24/24; live 7/7 | Tidak |
| 2026-10-14 | N-10 | `assistant.service.ts`, + `assistant-context-access.spec.ts` | `tsc --noEmit`, `npx jest` (env lokal + CI) | tsc OK; 16/16 suite, 149/149 | Tidak (10 test asisten lama tetap lolos) |
| 2026-10-13 | P0-06 | `evidence.service.ts`, `travel.service.ts`, + `evidence-idempotency-ownership.spec.ts`, + `travel-idempotency-ownership.spec.ts` | `tsc --noEmit`, `npx jest` (env lokal + CI) | tsc OK; 15/15 suite, 140/140 | Tidak |
| 2026-10-13 | N-08 | `evidence_deletion_policy.dart` (baru), `delete_evidence.dart`, `evidence_viewer_page.dart`, `geotag_camera_local_datasource.dart` (`deletePhoto` + guard), `sync_local_datasource.dart` (+`getRecordsByEntityLocalId` baca-saja), `evidence_gallery_and_media_test.dart` (2 test lama diubah ke perilaku baru), `test/features/evidence_gallery/evidence_original_protection_test.dart` (baru) | `flutter analyze`, `flutter test` | analyze = baseline (243 info, identik); suite penuh 414/414; setelah penyederhanaan terakhir suite terdampak 32/32 | Tidak (2 test lama sengaja diubah karena mengunci perilaku yang dihentikan) |
| 2026-10-13 | P0-03 | `evidence.service.ts` + `evidence-deletion.spec.ts` | `tsc --noEmit`, `npx jest` (env lokal + env CI) | tsc OK; 13/13 suite, 129/129 | Tidak (5 test evidence lama tetap lolos) |
| 2026-10-13 | P0-05 | `sync_queue_repository.dart` (+1 method interface), `sync_queue_repository_impl.dart`, `process_sync_queue.dart`, 2 fake test (`account_feature_test.dart`, `home_dashboard_integration_test.dart`) + `test/features/sync_queue/sync_interrupted_upload_recovery_test.dart` | `flutter analyze`, `flutter test` (penuh) | analyze = baseline; 402/402 | Tidak |
| 2026-10-13 | P0-02 | 3 route auth, + `lib/auth-backend.ts`, + `auth-routes.test.ts`, + `vitest.config.mts`, `package.json` (+vitest, script `test`), `package-lock.json` (+94 paket, 0 versi existing berubah) | `tsc --noEmit`, `eslint`, `vitest run`, runtime `next dev` | tsc OK; eslint = baseline (2 error, 3 warning, sama persis); vitest 24/24; runtime 503 tanpa cookie | Tidak |
