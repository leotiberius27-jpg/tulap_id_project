# Tulap Mobile

Tulap Mobile adalah aplikasi Android/iOS berbasis Flutter untuk pegawai lapangan yang melakukan dokumentasi tugas, geotag bukti kegiatan, validasi lokasi, scan nota, dan sinkronisasi offline-first.

Tujuan utama aplikasi ini adalah memastikan bukti lapangan dapat dipercaya, aman, dan terdokumentasi dengan baik di lokasi kerja, bahkan saat sinyal lemah atau offline.

## Fokus rilis awal

- Field evidence capture dengan GPS dan geotag
- Validasi anti-fake GPS dan anti-root/jailbreak
- Offline-first sync queue
- OCR nota dan data lapangan
- Autentikasi dan task management
- Build Android release yang siap ke Play Store

## Hasil inti yang sudah diperkuat

- Lokasi realtime dengan filter kualitas dan smoothing
- Deteksi data GPS stale dan posisi tidak realistis
- Tier status GPS: verified / freshRefining / fastInitial
- Task model siap menerima target latitude/longitude + radius tugas
- Geofence helper siap dipakai untuk validasi area kerja

## Quick start

```bash
cd tulap_mobile
flutter pub get
flutter analyze
flutter test
```

## Build release

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://your-api-host
```

## Catatan penting

- Fokus pengembangan utama adalah Android mobile untuk rilis awal.
- Background tracking lokasi tidak digunakan; aplikasi hanya memakai lokasi foreground saat capture atau pengecekan tugas.
- Keamanan dan audit dokumen bukti lebih diutamakan daripada fitur non-inti.

## Lisensi

Proyek ini dibuat untuk kebutuhan operasional lapangan dan internalisasi kerja berbasis lokasi.
