# TURLAP.ID — Gap Analysis

**Tanggal:** 2026-10-13. **Dasar:** `docs/architecture/EXISTING_SYSTEM_AUDIT.md`.

**Legenda aksi:**
- **KEEP**: pertahankan.
- **IMPROVE**: sempurnakan.
- **MOVE_TO_WEB**: pindahkan tanggung jawab UI ke web, dengan syarat di §3.
- **INTEGRATE**: hubungkan modul yang sudah ada.
- **BUILD**: buat yang belum ada.
- **DEPRECATE**: usulkan penghentian setelah migrasi dan persetujuan.

**Prioritas:**
- P0: integritas data, keamanan, bug kritis.
- P1: capture lapangan dan sync andal.
- P2: Web Drive dan verifikasi.
- P3: OCR dan LPJ.
- P4: analitik dan optimasi.

---

## 1. Matriks Gap

### 1.1 Keamanan & integritas (lintas aplikasi)

| Module | Existing | Target | Gap | Priority | Action |
|---|---|---|---|---|---|
| Laporan kegiatan (`/lpj/report/*`) | Disimpan di `Audit_Log.metadata`; tanpa cek kepemilikan | Tabel sendiri, otorisasi per-tugas | IDOR baca/tulis/hapus; audit log tercemar | P0 | IMPROVE (tabel `Activity_Report` + guard), migrasi data dari audit log tanpa menghapus log lama |
| Akses file bukti | Bucket anonymous-read, URL publik permanen | Bucket privat + presigned GET berumur pendek | Semua bukti dapat diakses siapa pun yang memegang URL | P0 | IMPROVE (bertahap, lihat Roadmap P0-03) |
| Sesi web | Fallback "demo admin" saat backend error | Gagal tertutup (fail-closed) | Sesi palsu | P0 | IMPROVE (hapus fallback) |
| Hapus bukti | Hard-delete kapan pun oleh PEGAWAI | Hanya sebelum submit; setelahnya soft-delete/arsip + alasan | Bukti bisa hilang setelah VERIFIED | P0 | IMPROVE |
| Integritas hash | Mismatch diterima, hash klien disimpan | Simpan `serverSha256`, `hashVerified`; tandai mismatch (flag) | Tidak ada jejak di record | P0 | IMPROVE |
| Isolasi instansi | String `instansiName` bebas, tanpa scoping | `Organization` + scoping semua query | Bocor lintas instansi | P0 (bila multi-instansi) | BUILD. **Butuh keputusan bisnis** (lihat §4) |
| Sesi & perangkat | JWT stateless, `DeviceToken` FCM saja | `Device` + `Session` (refresh token hash, revoke) | Tidak bisa mencabut HP hilang | P1 | BUILD (aditif) |
| Backup | Tidak ada | pg_dump + mirror MinIO terjadwal + uji restore | Risiko kehilangan permanen | P1 | BUILD (ops) |
| Hardening HTTP | CORS terbuka, tanpa helmet | Allowlist origin, helmet | Minor | P1 | IMPROVE |

### 1.2 Android (Field Operations)

| Module | Existing | Target | Gap | Priority | Action |
|---|---|---|---|---|---|
| Login & sesi | Email/Google/Apple/FB/Firebase, biometrik, secure storage | Sama + info perangkat terdaftar | Tidak ada device ID terdaftar | P1 | KEEP + IMPROVE |
| Tugas & detail | Lengkap, start/submit/resubmit | Sama | — | — | KEEP |
| Kamera geotag + watermark | Original & watermark terpisah di lokal; hanya watermark yang diunggah | Unggah original **dan** preview; metadata lengkap | Original tidak pernah sampai server; metadata dibuang | P1 | IMPROVE |
| Mock location | Blokir capture + lapor security event | Indikator risiko yang dapat ditinjau | Keputusan kebijakan: blokir vs tandai | P1 | **Keputusan user** (default: pertahankan blokir, tambah flag) |
| Root detector | Fail-open | Tri-state (aman/terdeteksi/tidak diketahui) | "Tidak diketahui" dilaporkan "aman" | P1 | IMPROVE |
| OCR nota | ML Kit on-device + preprocessing + parser + koreksi manual | Sama + field terstruktur tersimpan di server | Field tambahan dibuang server | P1/P3 | KEEP + INTEGRATE |
| Outbox & sync | Outbox FIFO, retry 5×, Sync Center | State target, backoff, recovery restart, presigned upload | Item `uploading` macet; tanpa backoff; multipart via API | **P0** (macet), P1 (sisanya) | IMPROVE |
| Quick Geotag | Lokal saja | Masuk outbox seperti bukti lain | Tidak sync | P1 | INTEGRATE |
| Sync Center | Ada | Tampilkan state baru + aksi "Perlu tindakan" | Tidak ada aksi untuk `uploading` | P0/P1 | IMPROVE |
| Profil & status perangkat | 14 halaman Akun | Profil dasar + status perangkat + penyimpanan | Terlalu banyak halaman pengaturan | P4 | KEEP (rapikan nanti) |
| Integritas lokal (`evidence_verification`) | Re-hash lokal | Tetap, label diganti "Cek Integritas" | Istilah "verifikasi" rancu | P4 | KEEP + IMPROVE (copy) |

### 1.3 Fitur Android untuk ditinjau (calon MOVE_TO_WEB)

| Module | Existing (Android) | Target | Gap | Priority | Action |
|---|---|---|---|---|---|
| LPJ Summary (`features/lpj`) | Ringkasan anggaran vs realisasi | Web: LPJ workspace | Web belum punya | P3 | MOVE_TO_WEB. Android: pertahankan **read-only** ringkas |
| Generate PDF laporan (`activity_report`) | PDF dibuat di device | Generate di server dari data terverifikasi | Ganda dengan `/lpj/generate` | P3 | MOVE_TO_WEB (generate). Android: lihat/unduh |
| Travel Mission / SPPD | CRUD penuh di mobile | Web: administrasi SPPD; Android: lihat + unggah dokumen lapangan | Web tidak ada | P3 | MOVE_TO_WEB (create/edit/LPJ package), KEEP (view + upload) |
| Dashboard analitik | Widget di Beranda | Web: analitik | — | P4 | MOVE_TO_WEB. Android: ringkasan "hari ini" |
| Pencarian arsip | Lintas entitas | Web: Drive search | — | P2 | MOVE_TO_WEB. Android: cari tugas sendiri |
| Buat kegiatan mandiri | PEGAWAI membuat tugas sendiri | ? | **Keputusan bisnis**: apakah pegawai boleh membuat tugas sendiri? | — | KEEP sampai diputuskan |
| Tanya Tulap | Keyword router | ? | Bukan AI; nilai operasional belum jelas | P4 | REVIEW / DEPRECATE (butuh persetujuan) |
| Langganan & pembayaran | Midtrans personal | ? | Model B2G (instansi) vs B2C personal belum jelas | — | REVIEW (butuh keputusan) |
| Peta sebaran | Google Maps (billing off) | Opsional | Butuh billing aktif | P4 | KEEP; aktifkan billing atau sembunyikan |

> **Catatan:** tidak ada fitur yang dihapus dari Android pada fase mana pun sebelum syarat §3 terpenuhi dan Anda menyetujui.

### 1.4 Web (Management & Document Workspace)

| Module | Existing | Target | Gap | Priority | Action |
|---|---|---|---|---|---|
| Auth web | Login, Google, Apple, reset | + refresh token, fail-closed | Sesi 15 menit, fallback demo | P0/P1 | IMPROVE |
| Dashboard | Daftar tugas | Ringkasan KPI | Belum ada KPI | P4 | IMPROVE (pakai `GET /dashboard`) |
| Manajemen tugas & penugasan | Create, list, detail | + edit (DRAFT), filter, pagination | Edit belum ada di UI | P2 | IMPROVE |
| Verification Workspace | Preview foto/nota + approve/revisi/tolak tugas | Antrean bukti, metadata GPS, waktu capture/upload, flag integritas, OCR, keputusan per-bukti, riwayat | Hanya keputusan level tugas; metadata minim | P2 | IMPROVE + BUILD |
| Web Drive | Tidak ada | Sidebar, All Evidence/Photos/Receipts/Documents/LPJ/Archive, search, preview, panel metadata | Semua | P2 | BUILD (folder virtual = query, bukan pindah file) |
| Koreksi OCR & pengeluaran | Tidak ada | Edit field nota terstruktur + verifikasi per-nota | Semua | P3 | BUILD |
| LPJ | Unduh PDF per-tugas (tidak disimpan) | Pilih bukti, tautkan nota, validasi, PDF + Word, versi, audit | Hampir semua | P3 | IMPROVE + INTEGRATE (pola `LPJ_Package`) |
| Pegawai & role | CRUD | + scoping instansi | Scoping | P0/P2 | IMPROVE |
| Manajemen perangkat | Tidak ada | Daftar & revoke | Semua | P1/P2 | BUILD |
| Audit log | Tidak ada viewer | Viewer + filter | UI | P2 | BUILD (API sudah ada) |
| Monitoring sync | Tidak ada | Status upload per pegawai/perangkat | Butuh data server | P2 | BUILD (setelah model Evidence baru) |
| Travel/SPPD | Tidak ada | Administrasi SPPD | Semua | P3 | BUILD (API sudah ada; perlu akses admin/verifikator) |
| Pengaturan | `href: '#'` | Pengaturan instansi | — | P4 | BUILD |
| Test & CI web | 0 | Lint + typecheck + build di CI, smoke e2e | Semua | P1 | BUILD |

### 1.5 Backend (Single Source of Truth)

| Module | Existing | Target | Gap | Priority | Action |
|---|---|---|---|---|---|
| Arsitektur | Modular monolith NestJS | Sama | — | — | KEEP |
| Evidence model | `Geotag_Photo` minim, video bercampur | Kolom metadata lengkap, original vs preview, status verifikasi | Banyak kolom hilang | P1 | IMPROVE (**migrasi aditif**: kolom nullable) |
| Upload flow | Multipart sinkron | register → presign PUT → finalize (+ multipart lama tetap didukung) | Belum ada | P1 | BUILD (kompatibel mundur) |
| Idempotensi | `dto.id` + hash; header `X-Idempotency-Key` diabaikan | `clientEvidenceId` unik + cek pemilik | Cek pemilik hilang | P0/P1 | IMPROVE |
| Verifikasi | Level tugas + `Task_Revision_Note` | + `Evidence_Verification` per-bukti | Per-bukti tidak ada | P2 | BUILD (aditif) |
| Nota | `Expense_Note` tanpa field detail; verifikasi tak pernah ditulis | Field terstruktur + endpoint verifikasi/koreksi + riwayat koreksi | Banyak | P3 | IMPROVE |
| LPJ | 3 jalur terpisah | 1 domain LPJ ber-versi | Fragmentasi | P3 | INTEGRATE |
| Background worker | Tidak ada | Queue untuk PDF/Word, thumbnail, OCR server (opsional) | Semua | P3 | BUILD (mulai in-process; BullMQ+Redis hanya bila perlu) |
| Firestore mirror | Cermin satu arah, opsional | Tidak dibutuhkan target | Sumber kedua | P4 | REVIEW / DEPRECATE (butuh persetujuan) |
| Test & CI | 11 suite, 1 gagal (fixture kedaluwarsa); CI tanpa test | CI menjalankan test; spec lpj/users/guard | Coverage dan CI | P1 | IMPROVE |

---

## 2. Ringkasan per Aksi

| Aksi | Item |
|---|---|
| **KEEP** | NestJS modular monolith, global guard + RBAC, state machine tugas, Audit_Log, Task_Revision_Note, outbox SQLite, kamera/watermark, OCR on-device, BFF web, LPJ_Package pattern, LocationFusionEngine |
| **IMPROVE** | Laporan kegiatan (keamanan), akses file (privat), auth web, hapus bukti, integritas hash, Evidence model, sync state machine + recovery, root detector, Sync Center, Verification Workspace, nota, CI |
| **MOVE_TO_WEB** | LPJ Summary, generate laporan PDF, administrasi Travel/SPPD, analitik, pencarian arsip penuh |
| **INTEGRATE** | Quick Geotag ke outbox, field OCR ke server, 3 jalur LPJ menjadi 1 |
| **BUILD** | Organization + scoping, Device/Session, presigned upload flow, verifikasi per-bukti, Web Drive, audit viewer, manajemen perangkat, monitoring sync, koreksi OCR web, LPJ Word, backup, test web |
| **DEPRECATE (usulan, butuh persetujuan)** | Firestore mirror; `cloud_firestore` di mobile; "Tanya Tulap" (atau label ulang); fallback demo web (ini langsung dihapus sebagai perbaikan P0, bukan deprecate fitur) |

---

## 3. Syarat MOVE_TO_WEB (berlaku untuk setiap item)

Sebuah fitur Android baru boleh **disembunyikan** (bukan dihapus) setelah semua syarat berikut terpenuhi:

1. Fungsi pengganti sudah tersedia di web dan lolos uji fungsional.
2. API dan database mendukungnya, termasuk akses peran yang tepat (mis. Travel API saat ini hanya per-user dan perlu akses verifikator/admin).
3. Data existing (SQLite lokal yang belum sync dan data server) tetap dapat diakses; tidak ada data lokal yang belum sync yang hilang.
4. Workflow pengguna tidak terputus. Pegawai tetap dapat melihat status dan hasil.
5. Test web + backend lulus; smoke test di perangkat fisik.
6. Ada rencana rollback berupa **feature flag** (remote atau build-time) yang dapat menampilkan kembali layar Android tanpa rilis ulang data.

Penghapusan kode dari Android hanya diusulkan setelah fitur tersembunyi minimal satu siklus rilis tanpa keluhan, dan dengan persetujuan eksplisit.

---

## 4. Keputusan yang Dibutuhkan dari Pemilik Produk

| # | Pertanyaan | Mengapa penting | Default yang diusulkan bila belum diputuskan |
|---|---|---|---|
| D1 | Apakah satu server melayani **lebih dari satu instansi**? | Menentukan apakah `Organization` + scoping adalah P0 | Asumsikan **ya** (aman), tetapi implementasi aditif |
| D2 | Mock location: **blokir** capture atau **izinkan + tandai** untuk ditinjau? | Prompt target menyebut "indikator risiko yang dapat ditinjau" | Pertahankan blokir + tambahkan flag dan alasan di server |
| D3 | Apakah PEGAWAI boleh membuat **kegiatan mandiri**? | Mempengaruhi alur penugasan | Pertahankan |
| D4 | Model bisnis: langganan **personal** (Midtrans) tetap ada? | Fitur berbayar di app B2G | Pertahankan, tidak disentuh |
| D5 | "Tanya Tulap": pertahankan, label ulang, atau hentikan? | Bukan AI, risiko klaim menyesatkan | Pertahankan, label "Bantuan Cepat" |
| D6 | **Template LPJ resmi** (regulasi/instansi) mana yang menjadi acuan? | Dilarang mengarang format keuangan | Pakai format PDF existing sebagai baseline |
| D7 | Apakah file **original** (tanpa watermark) wajib diunggah? | Kuota storage dan data seluler vs nilai bukti | Ya, untuk foto. Video: hanya hash dulu |
| D8 | Firestore mirror: masih dipakai sistem lain? | Bila tidak, dapat dihentikan | Biarkan apa adanya |
