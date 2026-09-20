# Draf Teks Store Listing — Google Play Console

Siap tempel langsung ke formulir **Store presence > Main store listing** di Play Console.

## Deskripsi Singkat (Short description)

Batas: 80 karakter. Teks di bawah: **79 karakter**.

```
Dokumentasi tugas lapangan pegawai: foto ber-geotag, checklist, dan LPJ digital
```

## Deskripsi Lengkap (Full description)

Batas: 4.000 karakter. Teks di bawah: **2.617 karakter**.

```
Tulap.id adalah aplikasi dokumentasi dan akuntabilitas kegiatan lapangan bagi pegawai instansi pemerintah dan organisasi lainnya. Dirancang khusus untuk petugas lapangan, Tulap.id menggantikan pencatatan manual dan laporan kertas dengan bukti digital yang akurat, terverifikasi, dan mudah dilacak — semuanya dari satu aplikasi.

FITUR UTAMA

📋 Manajemen Tugas Dinas
Kelola seluruh tugas dan kegiatan lapangan Anda dalam satu tempat. Setiap tugas dilengkapi checklist langkah kerja, sehingga progres penyelesaian selalu jelas bagi Anda maupun atasan.

📸 Dokumentasi Foto Ber-Geotag
Ambil foto bukti kegiatan langsung dari aplikasi. Setiap foto otomatis disematkan watermark geotag berisi koordinat lokasi, nama wilayah, waktu pengambilan, dan kode verifikasi — mencegah manipulasi dan memastikan keaslian bukti lapangan.

🧾 Pemindaian Nota & Laporan Pertanggungjawaban (LPJ)
Foto struk/nota pengeluaran langsung dipindai dan diolah otomatis (OCR) untuk mempercepat penyusunan Laporan Pertanggungjawaban, mengurangi kesalahan input manual.

✈️ Perjalanan Dinas
Catat dan kelola dokumen perjalanan dinas Anda, dari perencanaan hingga pelaporan, secara terintegrasi dengan riwayat kegiatan Anda.

📶 Sinkronisasi Offline-First
Tetap bisa bekerja di lokasi dengan sinyal terbatas. Data yang Anda buat tersimpan aman di perangkat dan otomatis tersinkronkan ke server begitu koneksi internet kembali tersedia — dengan status sinkronisasi yang transparan di layar Anda.

🔔 Notifikasi & Pengingat
Dapatkan pengingat tugas yang perlu diselesaikan dan status sinkronisasi data secara real-time.

🖥️ Dasbor Verifikasi untuk Atasan
Atasan dan verifikator instansi dapat memantau, memverifikasi, dan menyetujui laporan kegiatan pegawai melalui dasbor web Tulap.id yang terintegrasi langsung dengan data dari aplikasi mobile.

🔒 Keamanan Data
Seluruh data dikirim melalui koneksi terenkripsi (HTTPS/TLS), kata sandi disimpan dalam bentuk hash aman, dan sesi login Anda dilindungi dengan penyimpanan terenkripsi di perangkat. Integritas setiap bukti kegiatan diverifikasi menggunakan checksum digital.

UNTUK SIAPA TULAP.ID?

Tulap.id dibangun untuk pegawai instansi pemerintah daerah dan organisasi yang membutuhkan pencatatan kegiatan lapangan yang akuntabel — mulai dari petugas lapangan, admin instansi, hingga atasan yang bertanggung jawab memverifikasi laporan.

Masuk menggunakan email/kata sandi atau akun Google Anda. Data pribadi Anda dikelola sesuai Kebijakan Privasi kami dan tunduk pada ketentuan perlindungan data yang berlaku di Indonesia.

Punya pertanyaan atau butuh bantuan? Hubungi kami di support@tulap.id.
```

## Catatan sebelum submit ke Play Console

- **URL Kebijakan Privasi**: formulir Data Safety Play Console mewajibkan URL publik yang bisa diakses siapa saja tanpa login. `docs/legal/privacy-policy.md` di repo ini perlu di-hosting sebagai halaman web publik dulu (mis. lewat tulap_web di rute `/privacy` atau `/legal/privacy-policy`, atau GitHub Pages) sebelum linknya bisa dipakai di sini.
- **Kategori aplikasi**: sarankan "Bisnis" (Business) atau "Produktivitas" (Productivity).
- **Target audiens**: pegawai dewasa/karyawan instansi — bukan aplikasi untuk anak-anak, isi Content Rating sesuai itu.
- **Screenshot**: Play Console mewajibkan minimal 2 screenshot untuk ponsel (disarankan 4–8) — ambil dari alur Beranda, Dokumentasi Foto Ber-Geotag, Checklist Tugas, dan Dasbor Verifikasi.
- **Ikon aplikasi**: sudah tersedia di `tulap_mobile/android/app/src/main/res/mipmap-*/ic_launcher.png` — Play Console butuh versi 512×512px terpisah untuk listing (bukan file APK), siapkan dari master asset desain jika ada.
