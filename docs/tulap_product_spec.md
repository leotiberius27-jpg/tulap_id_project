# Tulap.id — Product & UI/UX Specification
### Tugas Lapangan, Disederhanakan.
*Dokumen ini adalah spesifikasi produk & desain profesional untuk tim UI/UX Designer dan Development Team.*

---

## 1. Executive Summary

Tulap.id adalah ekosistem digital (Mobile App + Web Dashboard) yang membantu ASN/pegawai pemerintah menjalankan tugas lapangan, mendokumentasikan bukti kegiatan, mendigitalkan nota, memvalidasi lokasi, dan menyusun LPJ/SPPD secara otomatis. Prinsip inti: **lebih sedikit mengetik, lebih sedikit mencari file, lebih sedikit mengulang pekerjaan.**

Kompleksitas teknis (OCR, checksum, geotagging, offline sync, integrity check) sepenuhnya disembunyikan dari user. User hanya melihat status sederhana seperti "Lokasi Valid", "Nota Tersimpan", "Menunggu Internet".

## 2. Product Vision

> "Tulap.id membantu pegawai membuktikan pekerjaannya dengan mudah — bukan mengawasi mereka."

Visi jangka panjang: menjadi asisten kerja lapangan standar bagi ASN di seluruh Indonesia, menggantikan alur kerja manual (WhatsApp + nota fisik + Excel LPJ) dengan satu alur digital yang tepercaya dan mudah diaudit.

## 3. Problem Statement

| # | Masalah | Dampak |
|---|---|---|
| 1 | Nota fisik pudar/hilang | LPJ tertunda, kerugian reimbursement |
| 2 | Input manual berulang | Beban administratif tinggi, human error |
| 3 | Bukti foto sulit diverifikasi | Temuan audit BPK/Inspektorat |
| 4 | Blank spot internet | Data hilang, pekerjaan terhambat |
| 5 | Fake GPS | Bukti tidak sah, potensi fraud |
| 6 | Instruksi tercecer di WhatsApp | Checklist terlewat, koordinasi buruk |

## 4. User Personas

**Pak Darto (52) — Petugas Lapangan Senior**
Kurang familiar aplikasi kompleks, butuh tombol besar & alur linear. Prioritas: cepat selesai, tidak takut "salah pencet".

**Bu Rina (34) — Verifikator**
Memeriksa puluhan bukti dan nominal pengeluaran per hari. Butuh workspace efisien, shortcut keyboard, dan indikator risiko cepat.

**Pak Anwar (45) — Admin Instansi**
Mengelola penugasan & pegawai, sekaligus memantau ringkasan progres tim untuk pimpinan. Butuh visibilitas progres tim dan kemudahan membuat tugas berulang.

**Ibu Sari (50) — Admin (Kepala Dinas)**
Menggunakan akses Admin terutama untuk melihat ringkasan cepat: berapa tugas berjalan, berapa yang perlu perhatian.

## 5. Jobs To Be Done

- Ketika saya menerima tugas dinas, saya ingin **tahu persis apa yang harus saya lakukan** tanpa membaca chat panjang.
- Ketika saya ambil foto kegiatan, saya ingin **bukti itu otomatis sah dan tidak perlu saya jelaskan lagi ke atasan**.
- Ketika saya terima nota, saya ingin **tidak perlu ketik ulang nominal**.
- Ketika sinyal hilang, saya ingin **pekerjaan saya tetap aman** dan lanjut otomatis saat online.
- Ketika saya memverifikasi, saya ingin **memutuskan cepat tanpa bolak-balik dokumen fisik**.

## 6. User Roles

| Role | Deskripsi | Permission Utama |
|---|---|---|
| **Petugas** | Pegawai lapangan | Lihat tugas sendiri, ambil foto, scan nota, kirim laporan |
| **Verifikator** | Memeriksa bukti, keuangan & LPJ | Lihat semua tugas dalam scope, approve/minta revisi, verifikasi nominal, lihat & rekap pengeluaran, ekspor laporan keuangan, generate LPJ |
| **Admin** | Mengelola instansi | CRUD pegawai, buat penugasan, atur template LPJ, lihat dashboard ringkas & laporan progres tim (read-only untuk kebutuhan pimpinan) |
| **Super Admin** | Kelola seluruh sistem/instansi | Semua akses + kelola instansi lain, konfigurasi global |

## 7. Information Architecture

```
Tulap.id
├── Mobile App (Petugas)
│   ├── Beranda
│   ├── Tugas (List → Detail → Checklist → Evidence)
│   ├── Kamera Geotag
│   ├── Scan Nota
│   ├── Riwayat
│   └── Akun
└── Web Dashboard (Admin/Verifikator)
    ├── Dashboard
    ├── Penugasan
    ├── Verifikasi (Workspace)
    ├── Peta
    ├── Keuangan
    ├── LPJ
    ├── Pegawai
    ├── Laporan
    └── Pengaturan
```

## 8. Mobile Sitemap

```
Login
 └─ Beranda ── Notifikasi
      ├─ Tugas List ── Detail Tugas ── Checklist
      │                     ├─ Kamera Geotag ── Preview Foto
      │                     ├─ Scan Nota ── Review OCR
      │                     └─ Kirim Tugas ── Sync Center
      ├─ Riwayat ── Detail Riwayat (read-only)
      └─ Akun ── Profil / Instansi / Logout
```

## 9. Web Sitemap

```
Login
 └─ Dashboard
      ├─ Penugasan ── Buat Tugas / Detail Tugas
      ├─ Verifikasi ── Verification Workspace (split-view)
      ├─ Peta
      ├─ Keuangan ── Detail Transaksi
      ├─ LPJ ── Generator ── Preview/Export
      ├─ Pegawai ── Tambah/Edit Pegawai
      ├─ Laporan
      └─ Pengaturan ── Template LPJ / Role / Instansi
```

## 10. Primary User Flow

```
Terima Tugas → Buka Instruksi → Datang ke Lokasi → Checklist
→ Foto Bukti (Geotag) → Scan Nota (OCR) → Simpan Otomatis (Lokal)
→ Sinkronisasi (saat online) → Kirim Tugas → Verifikasi (Verifikator)
→ [Perlu Diperbaiki → Revisi] atau [Disetujui] → LPJ Dibuat Otomatis
```

## 11. Mobile Screen-by-Screen Specification

### 11.1 Beranda
- **Tujuan**: Jawab 3 pertanyaan dalam detik — tugas saya apa, langkah berikutnya, data saya aman?
- **Informasi**: Header (logo, sapaan, nama, instansi, notifikasi, avatar), Kartu Tugas Aktif, Quick Actions, Sync Status.
- **Component hierarchy**: HomeHeader → ActiveTaskCard → QuickActionGrid → SyncStatusBanner
- **Primary CTA**: "Lanjutkan Tugas"
- **Secondary CTA**: Quick Actions (Foto Kegiatan, Scan Nota, Lokasi, Lihat LPJ)
- **Empty state**: "Belum ada tugas aktif hari ini." + ilustrasi tenang
- **Loading state**: Skeleton card
- **Error state**: "Data belum bisa dimuat. Coba lagi." + tombol Muat Ulang
- **Offline state**: Banner "Tidak Ada Internet — Pekerjaan Anda tetap tersimpan di perangkat."
- **Mobile layout**: Single column, scroll vertikal, card 16px radius

### 11.2 Detail Tugas ("Satu Tugas = Satu Folder Pintar")
- **Tujuan**: Pusat kendali satu tugas — instruksi, checklist, bukti, status.
- **Informasi**: Judul, ID Tugas, lokasi, jadwal, deadline, instruksi, checklist progres, bukti wajib, foto, nota, catatan, status sync & verifikasi.
- **Component hierarchy**: TaskHeader → ChecklistList → EvidenceGrid → ExpenseList → StatusBanner
- **Primary CTA**: "Lanjutkan Pekerjaan" / "Selesaikan Tugas"
- **Secondary CTA**: "Lengkapi Bukti" (jika bukti wajib belum lengkap)
- **Empty state**: "Belum ada bukti diunggah untuk tugas ini."
- **Error state**: "1 bukti wajib belum lengkap." dengan highlight item
- **Offline state**: Checklist tetap bisa diisi, badge "Tersimpan di HP"

### 11.3 Kamera Geotag (full-screen)
- **Tujuan**: Ambil bukti foto yang tervalidasi lokasi & waktu.
- **Informasi**: Watermark (nama petugas, instansi, ID Tugas, lat/long, alamat, tanggal, jam server), indikator GPS.
- **Component hierarchy**: CameraTopBar (Back, Flash, GPS status) → WatermarkOverlay → TaskGalleryStrip → CaptureButton
- **Primary CTA**: Tombol capture besar
- **Setelah capture**: Preview → "Gunakan Foto" (primary) / "Ambil Ulang" (secondary)
- **GPS Valid**: badge hijau "Lokasi Valid"
- **GPS Invalid**: badge merah "Lokasi Tidak Valid" — capture bukti resmi diblokir, modal merah muncul jika mock location terdeteksi
- **UX copy blocking modal**: "Lokasi perangkat tidak valid. Nonaktifkan lokasi palsu untuk melanjutkan."

### 11.4 Scan Nota (OCR)
- **Flow**: Kamera → Crop/Deteksi → OCR → Review (bottom sheet) → Konfirmasi
- **Review sheet menampilkan**: Vendor, Nominal (besar), Kategori, Tanggal, No. Nota, Pajak, Item (jika ada), confidence indicator
- **Primary CTA**: "Simpan Nota"
- **Secondary CTA**: "Edit"
- **Error state**: "Nominal belum terbaca jelas, silakan periksa." (bukan "OCR gagal")
- **Duplicate warning**: "Nota ini tampaknya sudah pernah digunakan." + tombol "Gunakan Tetap" / "Batalkan"

### 11.5 Sync Center
- **Status list**: Tersimpan → Menunggu Internet → Mengirim → Terkirim → Gagal (dengan retry)
- **Primary CTA per item gagal**: "Coba Kirim Lagi"
- **Empty state**: "Semua data sudah terkirim." + ikon centang hijau

### 11.6 Riwayat
- **Informasi per baris**: Tanggal, nama tugas, jumlah foto, jumlah nota, status
- **Filter**: Hari ini / Minggu ini / Bulan ini / Selesai / Perlu Diperbaiki
- **Empty state**: "Belum ada riwayat tugas."

### 11.7 Akun
- **Informasi**: Profil, instansi, unit kerja, pengaturan notifikasi, kelola sesi perangkat, logout
- **CTA**: "Keluar" dengan dialog konfirmasi "Yakin ingin keluar dari Tulap.id?"

## 12. Web Screen-by-Screen Specification

### 12.1 Dashboard (Admin)
- **Card**: Tugas Aktif, Selesai Hari Ini, Menunggu Verifikasi, Perlu Perhatian
- **Sections**: Progress seluruh tugas, Recent Activity, Warning List, Verification Queue
- **Desktop layout**: 4-column card grid → 2-column content (activity + queue)

### 12.2 Verification Workspace (split-view)
- **Kiri**: Photo/receipt viewer — zoom, pan, rotate, metadata (GPS, jam server, SHA-256), badge "Integritas Bukti Terverifikasi"
- **Kanan**: Info tugas, petugas, checklist audit, data nota, catatan
- **Primary CTA**: "Setujui" | "Perlu Diperbaiki" | "Konfirmasi Penolakan" (khusus kasus ekstrem)
- **Keyboard shortcuts**: A = Approve, R = Revision, ← / → = navigasi item
- **Revision UX**: Verifikator menunjuk item spesifik — contoh: "Nota BBM — Nominal kurang jelas.", "Foto #3 — Foto terlalu gelap.", "Lokasi — di luar radius tugas."

### 12.3 Penugasan
- **Form**: Judul, deskripsi, petugas, lokasi, radius, jadwal, deadline, checklist, jenis bukti wajib, dokumen instruksi, catatan, reviewer
- **Primary CTA**: "Buat Tugas"

### 12.4 Peta
- **Layer**: Lokasi tugas, bukti foto, warning, geofence, status
- **Filter**: Semua / Aktif / Selesai / Perlu Perhatian
- **Prinsip privasi**: TIDAK ada continuous tracking; hanya titik lokasi terkait tugas & waktu capture eksplisit

### 12.5 Keuangan
- **Card**: Total Pengeluaran, Menunggu Verifikasi, Disetujui, Perlu Diperbaiki
- **Table**: Vendor, Kategori, Tanggal, Nominal, Petugas, Tugas, Status

### 12.6 LPJ Generator
- **Flow**: Pilih Tugas → Sistem kumpulkan data → Review → Generate
- **Output**: PDF / Word / Print, template per instansi
- **Primary CTA**: "Cetak LPJ"

## 13. Wireframe (ASCII)

**Beranda (Mobile)**
```
┌─────────────────────────────┐
│ ☰  Tulap.id       🔔  👤    │
│ Selamat Pagi, Pak Darto      │
│ Dinas Pekerjaan Umum         │
├─────────────────────────────┤
│ TUGAS AKTIF                  │
│ ┌───────────────────────────┐│
│ │ Inspeksi Jembatan Ciliwung││
│ │ 📍 Jakarta Timur          ││
│ │ ⏰ Hari ini, 14:00        ││
│ │ ▓▓▓▓░░░░  3/6 selesai     ││
│ │ [ Lanjutkan Tugas ]       ││
│ └───────────────────────────┘│
├─────────────────────────────┤
│ AKSI CEPAT                   │
│ [📷 Foto] [🧾 Nota] [📍 Lok] │
├─────────────────────────────┤
│ ✅ Semua data sudah terkirim │
├─────────────────────────────┤
│ 🏠   📋   📷   🕓   👤       │
└─────────────────────────────┘
```

**Kamera Geotag (Mobile)**
```
┌─────────────────────────────┐
│ ←        🟢 GPS Valid    ⚡  │
│                               │
│      [ LIVE CAMERA VIEW ]    │
│                               │
│  Tulap.id — Pak Darto         │
│  Dinas PU · Tugas #TL-0231    │
│  -6.2088, 106.8456            │
│  Jl. Kalibata, Jakarta        │
│  10 Agu 2026 · 14:02:11 WIB   │
│                               │
│ [🖼️🖼️🖼️]        (  ⚪️  )     │
└─────────────────────────────┘
```

**Verification Workspace (Web)**
```
┌───────────────────┬─────────────────────┐
│  [FOTO/NOTA VIEWER]│ Tugas: Inspeksi ...  │
│                     │ Petugas: Pak Darto   │
│  🔒 Integritas      │ ☑ Foto kondisi awal  │
│    Terverifikasi    │ ☑ Foto kegiatan      │
│  GPS: Valid          │ ☐ Scan nota          │
│  Jam server: 14:02   │ Catatan: -           │
│                     │                       │
│                     │ [Setujui] [Perlu      │
│                     │  Diperbaiki]          │
└───────────────────┴─────────────────────┘
```

## 14. Design System

### 14.1 Color Tokens
| Token | Hex | Fungsi |
|---|---|---|
| color.primary | #00529C | Navy — brand utama |
| color.primary.hover | #003D75 | Hover state |
| color.action | #0072CE | Tombol aksi interaktif |
| color.success | #10B981 | Terverifikasi / Disetujui |
| color.warning | #F59E0B | Perlu perhatian |
| color.danger | #EF4444 | Lokasi tidak valid / gagal |
| color.background | #F7F9FC | Latar layar |
| color.surface | #FFFFFF | Kartu/panel |
| color.text.primary | #172033 | Teks utama |
| color.text.secondary | #667085 | Teks pendukung |
| color.border | #EAECF0 | Garis pemisah |

### 14.2 Typography
| Level | Ukuran/Weight |
|---|---|
| Display | 32px Bold |
| Page Title | 24px Bold |
| Section Title | 18px Semibold |
| Body | 16px Regular |
| Small | 14px Medium |

Font utama: **Plus Jakarta Sans**, fallback **Inter**. Minimum body mobile: 14px.

### 14.3 Spacing (8px base)
`4 · 8 · 12 · 16 · 24 · 32 · 40 · 48 · 64` — padding layar default 16px (mobile), 24–32px (desktop).

### 14.4 Radius
Small: 8px · Button: 12px · Card: 16px · Bottom Sheet: 24px (top).

### 14.5 Button
Height 52px (mobile), radius 12px, minimum touch target 44×44px.

## 15. Figma Tokens (contoh struktur JSON)

```json
{
  "color": {
    "primary": { "value": "#00529C" },
    "action": { "value": "#0072CE" },
    "success": { "value": "#10B981" },
    "warning": { "value": "#F59E0B" },
    "danger": { "value": "#EF4444" },
    "background": { "value": "#F7F9FC" },
    "surface": { "value": "#FFFFFF" },
    "text": {
      "primary": { "value": "#172033" },
      "secondary": { "value": "#667085" }
    },
    "border": { "value": "#EAECF0" }
  },
  "spacing": { "4":"4","8":"8","12":"12","16":"16","24":"24","32":"32","40":"40","48":"48","64":"64" },
  "radius": { "small":"8","button":"12","card":"16","sheet":"24" }
}
```

## 16. Component Library

- **Foundation**: Color, Typography, Spacing, Radius, Elevation, Icon, Motion
- **Atoms**: Button, Icon Button, Text Input, Checkbox, Radio, Chip, Badge, Avatar, Divider, Progress, Skeleton
- **Molecules**: Quick Action, Task Card, Receipt Card, Sync Row, User Header, Location Card, Status Banner, Checklist Item, Upload Item
- **Organisms**: Home Header, Active Task, Quick Action Grid, Camera Overlay, Receipt Review Sheet, Task Detail, Verification Panel, Map Filter Bar, Finance Summary, LPJ Preview
- **Templates**: Mobile Home, Task Detail, Camera, Receipt Scanner, Sync Center, Web Dashboard, Verification Workspace, Map, Finance, LPJ

## 17. UX Copywriting (kamus istilah)

| Istilah Teknis | Copy User-Facing |
|---|---|
| Synchronization failed | Data belum berhasil dikirim. |
| Invalid metadata | Informasi foto belum lengkap. |
| Mock location detected | Lokasi perangkat tidak valid. |
| GPS accuracy low | Memeriksa lokasi… |
| OCR confidence low | Nominal kurang jelas, mohon periksa. |
| Task rejected | Perlu Diperbaiki |
| Upload success | Data Terkirim |

Tone: jelas, tenang, tidak menyalahkan user, singkat, operasional.

## 18. State & Error Handling

Setiap layar utama wajib mendefinisikan: Empty, Loading, Error, Offline (jika relevan) — lihat detail di Bagian 11 & 12 per layar. Prinsip umum: error selalu disertai *next action* yang jelas, tidak pernah dead-end.

## 19. Offline UX

Status: **Tersimpan di HP → Menunggu Internet → Sedang Mengirim → Terkirim**. Copy: "Tidak Ada Internet — Pekerjaan Anda tetap tersimpan di perangkat. 3 data menunggu dikirim." CTA: "Lihat Data". Sync Center menampilkan retry manual untuk item Gagal.

## 20. OCR Flow

`Scan Nota → Kamera → Crop/Deteksi → OCR → Review (bottom sheet) → Konfirmasi → Simpan Nota`
Review menampilkan confidence indicator per field; field dengan confidence rendah ditandai kuning agar user memeriksa manual sebelum simpan.

## 21. Camera UX

Full-screen, watermark semi-transparan, indikator GPS real-time (hijau/merah), capture diblokir saat mock location terdeteksi (modal blocking merah), microinteraction haptic + flash saat capture.

## 22. Verification Flow

`Masuk Queue (diurutkan risiko: warning, nominal besar, GPS anomaly, missing data, deadline) → Buka Split-View → Periksa Foto/Nota → Setujui / Perlu Diperbaiki (dengan catatan per item) → Notifikasi ke Petugas → [jika revisi] Petugas Perbaiki → Verifikasi Ulang`

## 23. Finance Flow

`Nota Masuk (OCR) → Masuk Daftar Pengeluaran (Menunggu Verifikasi) → Verifikator Cek Nominal → Disetujui/Perlu Diperbaiki → Terhubung ke LPJ`

## 24. LPJ Flow

`Pilih Tugas → Sistem Kumpulkan Data (foto, nota, checklist, verifikasi) → Review → Generate (PDF/Word, template per instansi) → Cetak/Unduh`

## 25. Notification System

| Trigger | Notifikasi |
|---|---|
| Tugas baru ditugaskan | "Tugas baru: [Judul] — [Tanggal]" |
| Deadline mendekat | "Tugas [Judul] jatuh tempo besok." |
| Perlu Diperbaiki | "Ada bagian yang perlu diperbaiki pada tugas [Judul]." |
| Disetujui | "Tugas [Judul] telah disetujui." |
| Sync gagal berulang | "3 data belum terkirim. Periksa koneksi Anda." |
| LPJ siap | "LPJ untuk [Judul] sudah bisa diunduh." |

## 26. Permission Model

| Aksi | Petugas | Verifikator | Admin | Super Admin |
|---|:---:|:---:|:---:|:---:|
| Lihat tugas sendiri | ✅ | ✅ | ✅ | ✅ |
| Ambil foto/nota | ✅ | ❌ | ❌ | ❌ |
| Approve/Revisi bukti | ❌ | ✅ | ❌ | ✅ |
| Verifikasi nominal | ❌ | ✅ | ❌ | ✅ |
| Buat penugasan | ❌ | ❌ | ✅ | ✅ |
| Kelola pegawai | ❌ | ❌ | ✅ | ✅ |
| Generate LPJ | ❌ | ✅ | ✅ | ✅ |
| Lihat dashboard ringkas | ❌ | ❌ | ✅ | ✅ |
| Kelola instansi lain | ❌ | ❌ | ❌ | ✅ |

## 27. Database Domain Model

**Entitas utama & relasi:**
- `Agency` 1—N `User` (satu instansi punya banyak pegawai)
- `Role` 1—N `User`
- `User` 1—N `TaskAssignment` N—1 `Task`
- `Task` 1—N `TaskChecklist`
- `Task` 1—N `Evidence` → subtipe `PhotoEvidence`, `Receipt`
- `Receipt` 1—1 `Expense`
- `PhotoEvidence` 1—1 `LocationRecord`
- `Task` 1—N `SyncRecord` (outbox pattern)
- `Task` 1—1 `Verification` → 1—N `Revision`
- `Task` 1—1 `LPJ` N—1 `LPJTemplate` (per `Agency`)
- `User` 1—N `Device` (session/device management)
- Semua entitas kunci menghasilkan entri di `AuditLog`
- `Notification` N—1 `User`

## 28. High-Level Technical Architecture

**Mobile**: Flutter (cross-platform), local DB offline-first (SQLite/Drift), background sync service, Clean Architecture (domain/data/presentation).

**Backend**: NestJS (modular), PostgreSQL (relasional), Redis (cache/queue), background worker untuk OCR & document generation, object storage S3-compatible (region Jakarta), Auth JWT dual-token + RBAC.

**Sync**: Outbox pattern — setiap aksi offline dicatat sebagai record pending, dikirim saat online dengan retry & conflict handling (last-write-wins atau manual resolve untuk kasus kritis).

## 29. API Domain Recommendation

`POST /auth/login` · `POST /tasks` · `GET /tasks/:id` · `POST /tasks/:id/checklist` · `POST /evidence/photo` · `POST /evidence/receipt` · `POST /sync/batch` · `GET /verification/queue` · `POST /verification/:id/approve` · `POST /verification/:id/request-revision` · `POST /lpj/generate` · `GET /finance/summary` · `GET /audit-logs`

## 30. Security Considerations

- TLS 1.3 in-transit, AES-256 at-rest (sesuai UU PDP No. 27/2022)
- SHA-256 checksum tiap file bukti asli, disimpan terpisah dari file
- Mock location & root/jailbreak detection sebelum capture bukti resmi
- RBAC ketat di setiap endpoint (lihat Bagian 26)
- Dual-token JWT dengan re-validasi status aktif user per request
- Rate limiting & audit log untuk aksi sensitif (approve, delete, export)

## 31. Audit Trail Design

Setiap perubahan data penting (buat tugas, capture bukti, approve, edit nominal, generate LPJ) dicatat di `AuditLog`: `actor_id`, `action`, `entity`, `entity_id`, `before/after (jika relevan)`, `timestamp`, `device_id`. Tidak dapat dihapus/diedit (append-only).

## 32. Privacy Considerations

Positioning: **"Tulap.id membantu pegawai membuktikan pekerjaannya"**, bukan alat pengawasan. Data minimization: lokasi hanya direkam saat capture bukti terkait tugas, bukan continuous tracking. User selalu tahu kapan lokasi diambil (indikator jelas saat kamera aktif).

## 33. Accessibility Checklist

- [ ] Kontras warna memenuhi WCAG AA
- [ ] Touch target minimal 44×44px
- [ ] Status tidak hanya mengandalkan warna (selalu + ikon + teks)
- [ ] Ukuran teks dapat diperbesar tanpa merusak layout
- [ ] CTA selalu jelas dan deskriptif (bukan hanya ikon)
- [ ] Bahasa error manusiawi, tanpa jargon teknis
- [ ] Kontras cukup untuk penggunaan outdoor
- [ ] Nominal ditampilkan besar & jelas
- [ ] Loading state selalu terlihat, tidak ada layar kosong tanpa indikator

## 34. Empty States

| Layar | Copy |
|---|---|
| Beranda (tanpa tugas) | "Belum ada tugas aktif hari ini." |
| Riwayat | "Belum ada riwayat tugas." |
| Sync Center | "Semua data sudah terkirim." |
| Verification Queue | "Tidak ada bukti yang menunggu diperiksa." |
| Keuangan | "Belum ada transaksi pada periode ini." |

## 35. Loading States

Skeleton card untuk list (Beranda, Riwayat, Tugas), circular progress untuk sync, shimmer pada thumbnail foto yang belum termuat penuh.

## 36. Error States

Format konsisten: **[apa yang terjadi] + [apa yang bisa dilakukan user]**. Contoh: "Data belum berhasil dikirim. Coba kirim lagi." — selalu sertai tombol aksi, tidak pernah pesan buntu.

## 37. Edge Cases

- Nota terpakai dua kali → duplicate detection + konfirmasi
- Foto lama dipakai ulang → hanya bukti dari kamera in-app yang diterima (metadata capture wajib)
- Petugas jauh dari lokasi tugas → geofence warning, tetap bisa capture tapi ditandai untuk review verifikator
- HP hilang/ganti → device management di Akun, admin bisa revoke session dari Web Dashboard
- Format LPJ beda tiap instansi → template per `Agency` di `LPJTemplate`
- Volume verifikasi tinggi → Verification Queue diurutkan otomatis berdasar risiko

## 38. MVP Scope

Login & profil · Penugasan · Checklist tugas · Kamera geotag · Validasi GPS · Scan nota OCR · Offline storage · Background sync · Task evidence · Verification dashboard · Revision flow · Expense records · LPJ generator · Audit trail · Notifikasi.

## 39. Phase 2 Features

Dashboard analitik lanjutan (tren pengeluaran, performa tim), template LPJ builder visual (drag-drop), multi-bahasa daerah, integrasi e-signature untuk LPJ, ekspor laporan ke sistem keuangan instansi (SIMDA/SAKTI jika relevan).

## 40. Features yang Sebaiknya Tidak Dibuat Dulu

Social feed internal, video conference, payroll, sistem chat kompleks, full HRIS, general document management, continuous employee surveillance, dan fitur apa pun yang tidak berhubungan langsung dengan tugas lapangan.

## 41. Product Metrics

- Waktu rata-rata penyelesaian LPJ (target: turun signifikan vs proses manual)
- Persentase bukti yang lolos verifikasi tanpa revisi
- Waktu rata-rata verifikasi per tugas
- Tingkat kegagalan sync (target mendekati 0%)
- Adoption rate pegawai senior (usability untuk kelompok ini jadi indikator kunci)

## 42. Developer Handoff Notes

- Semua warna, spacing, radius WAJIB pakai token, tidak hardcode hex/px
- Status selalu pasangan ikon + teks + warna (bukan warna saja)
- Komponen kamera & OCR harus modular agar mudah diganti provider (mis. OCR engine)
- Setiap state (empty/loading/error/offline) wajib diimplementasikan sebelum fitur dianggap selesai
- Microinteraction (haptic, toast, animasi) mengikuti Bagian 28, jangan ditambah berlebihan

## 43. Figma Page Structure

```
00 Cover
01 Foundations
02 Tokens
03 Icons
04 Components
05 Mobile
06 Web
07 Prototype
08 User Flows
09 Documentation
10 Developer Handoff
```

## 44. Naming Convention

`ComponentGroup/Variant/Size` — contoh: `Button/Primary/Large`, `Button/Secondary/Large`, `Badge/Success`, `Badge/Warning`, `TaskCard/Active`, `TaskCard/Completed`, `ReceiptCard/Verified`, `SyncRow/Pending`. Konsisten Title Case, tanpa spasi ganda, gunakan `/` sebagai pemisah hierarki di Figma.

## 45. Final Recommendation

Mulai dari MVP yang benar-benar ramping (Bagian 38), uji langsung ke petugas senior sebagai pengguna utama sebelum menambah fitur apa pun. Setiap keputusan desain baru harus lolos uji: **"Apakah ini membuat pekerjaan pegawai lebih cepat dan lebih mudah?"** — jika tidak, tunda ke Phase 2. Jaga visual tetap tenang dan tepercaya (inspirasi BRImo tanpa meniru literal), karena kepercayaan pegawai senior terhadap aplikasi ini akan menentukan tingkat adopsi jangka panjang.

---
*Dokumen ini menjadi acuan utama untuk desain Figma dan implementasi teknis Tulap.id. Selaras dengan Prisma Schema, struktur folder Clean Architecture, dan Auth/RBAC Module yang telah dibangun sebelumnya.*
