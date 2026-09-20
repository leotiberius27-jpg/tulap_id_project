# Kebijakan Privasi Tulap.id

**Terakhir diperbarui: 20 September 2026**

Kebijakan Privasi ini menjelaskan bagaimana Tulap.id ("kami", "Aplikasi", "Layanan") mengumpulkan, menggunakan, menyimpan, dan melindungi data pribadi Anda sebagai pengguna — baik melalui aplikasi mobile Tulap.id (Android/iOS) maupun dasbor web Tulap.id yang digunakan oleh instansi/atasan Anda.

Tulap.id adalah aplikasi dokumentasi dan akuntabilitas kegiatan lapangan bagi pegawai instansi (mis. dinas pemerintah daerah, BUMN, atau organisasi lain yang menggunakan layanan kami), dengan fitur utama berupa pencatatan tugas, dokumentasi foto ber-geotag, pemindaian nota pengeluaran, penyusunan Laporan Pertanggungjawaban (LPJ), pencatatan perjalanan dinas, dan dasbor verifikasi bagi atasan/verifikator.

> **Catatan bagi pengelola Tulap.id:** dokumen ini adalah draf awal yang disusun berdasarkan fitur aplikasi yang sudah berjalan. Sebelum dipublikasikan sebagai dokumen hukum resmi (terlebih untuk aplikasi yang dipakai instansi pemerintah), sebaiknya direview oleh penasihat hukum (Legal Counsel) dan, jika relevan, Data Protection Officer (DPO) instansi Anda — khususnya bagian kepatuhan UU No. 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP) dan ketentuan internal instansi pengguna. Isi bagian bertanda `[...]` sebelum dipublikasikan.

## 1. Data yang Kami Kumpulkan

### a. Data yang Anda berikan langsung
- **Data identitas akun**: nama lengkap, NIP (jika berlaku), email, nomor HP, nama instansi, unit kerja, foto profil.
- **Kata sandi**: disimpan dalam bentuk hash terenkripsi (bcrypt) — kami tidak pernah menyimpan kata sandi dalam bentuk teks biasa, dan tidak dapat melihatnya.
- **Data kegiatan/tugas**: judul dan deskripsi tugas, status checklist, catatan lapangan.
- **Dokumentasi foto**: foto kegiatan yang Anda ambil melalui kamera dalam aplikasi, termasuk watermark geotag (koordinat GPS, nama wilayah, waktu pengambilan) yang disematkan pada foto sebagai bukti keaslian.
- **Data nota/pengeluaran**: foto struk/nota dan hasil pemindaian teks otomatis (OCR) untuk keperluan penyusunan LPJ dan pencatatan perjalanan dinas.
- **Data pembayaran/langganan**: jika Anda atau instansi Anda berlangganan paket Tulap.id berbayar, data transaksi (nominal, status, referensi pembayaran) diproses melalui mitra payment gateway kami (Midtrans). Kami **tidak** menyimpan detail kartu pembayaran Anda — proses ini sepenuhnya ditangani oleh mitra payment gateway yang telah tersertifikasi PCI-DSS.

### b. Data yang dikumpulkan otomatis
- **Data lokasi (GPS)**: koordinat lokasi **hanya** direkam pada saat Anda menekan tombol rana kamera untuk menyematkan watermark geotag pada bukti dokumentasi, atau saat Anda secara eksplisit membuka fitur peta/lokasi tugas. **Tulap.id tidak melakukan pelacakan lokasi secara terus-menerus di latar belakang.**
- **Token notifikasi**: token perangkat (Firebase Cloud Messaging) untuk mengirimkan notifikasi pengingat tugas dan status sinkronisasi.
- **Data teknis dasar**: jenis perangkat, versi sistem operasi, dan log teknis terbatas untuk keperluan diagnosis kesalahan aplikasi.
- **Data sinkronisasi offline**: aplikasi menyimpan data sementara di perangkat Anda (database lokal terenkripsi) ketika tidak ada koneksi internet, dan mengirimkannya ke server pusat begitu koneksi tersedia kembali.

## 2. Izin Perangkat (Permissions) yang Digunakan

| Izin | Tujuan Penggunaan |
|---|---|
| Kamera | Mengambil foto dokumentasi kegiatan dan memindai nota pengeluaran. Kamera hanya aktif saat Anda membuka fitur pengambilan foto. |
| Lokasi (GPS) | Menyematkan watermark geotag pada foto bukti kegiatan dan menampilkan lokasi tugas di peta. Tidak digunakan untuk pelacakan latar belakang. |
| Notifikasi | Mengirim pengingat tugas dan status sinkronisasi data. |
| Internet & Status Jaringan | Mengirim dan menerima data antara aplikasi dan server, serta mendeteksi status koneksi untuk mode offline-first. |
| Mikrofon | Diminta oleh salah satu pustaka pihak ketiga yang digunakan untuk fitur kamera/media. **Tulap.id tidak merekam maupun memproses audio dari mikrofon Anda** — izin ini tidak dipakai aktif oleh fitur apa pun saat ini. |

Anda dapat mencabut izin-izin ini kapan saja melalui pengaturan sistem operasi perangkat Anda; sebagian fitur (mis. dokumentasi foto ber-geotag) tidak akan berfungsi tanpa izin yang relevan.

## 3. Bagaimana Kami Menggunakan Data Anda

Kami menggunakan data yang dikumpulkan untuk:
1. Menyediakan dan mengoperasikan fitur inti Layanan (autentikasi, pencatatan tugas, dokumentasi bukti, penyusunan LPJ, perjalanan dinas).
2. Memverifikasi keaslian bukti kegiatan lapangan (watermark geotag, checksum integritas berkas SHA-256) untuk kebutuhan akuntabilitas instansi Anda.
3. Menampilkan data kegiatan Anda kepada atasan/verifikator di instansi Anda melalui dasbor web Tulap.id, sebatas yang diperlukan untuk proses verifikasi dan pelaporan.
4. Mengirimkan notifikasi terkait tugas dan status akun.
5. Menjaga keamanan akun dan mencegah penyalahgunaan (mis. mendeteksi upaya masuk yang mencurigakan).
6. Memproses pembayaran langganan (jika berlaku).
7. Memenuhi kewajiban hukum dan permintaan resmi dari instansi Anda terkait data kepegawaian yang tersimpan di Layanan.

## 4. Berbagi Data dengan Pihak Ketiga

Kami **tidak menjual** data pribadi Anda kepada pihak mana pun. Data Anda dapat diakses/diproses oleh pihak ketiga berikut, sebatas yang diperlukan untuk menjalankan Layanan:

- **Google Firebase** (Firebase Authentication, Cloud Messaging, Firestore) — untuk autentikasi masuk (termasuk Masuk dengan Google) dan pengiriman notifikasi.
- **Penyedia penyimpanan berkas kompatibel S3** — untuk menyimpan foto dokumentasi dan berkas nota secara terenkripsi dalam pengiriman (HTTPS/TLS).
- **Midtrans** — sebagai mitra payment gateway untuk memproses pembayaran langganan, jika Anda/instansi Anda menggunakan fitur berpembayaran.
- **Instansi/atasan Anda** — data kegiatan dan dokumentasi Anda ditampilkan kepada pihak yang berwenang di instansi Anda (mis. atasan langsung, verifikator LPJ) sesuai peran (role) yang ditetapkan instansi, sebagai bagian normal dari fungsi akuntabilitas Layanan.
- **Otoritas hukum**, apabila diwajibkan oleh proses hukum yang sah.

Kami mewajibkan seluruh mitra pihak ketiga untuk menjaga kerahasiaan dan keamanan data sesuai standar yang setara dengan komitmen kami dalam kebijakan ini.

## 5. Keamanan Data

- Seluruh komunikasi antara aplikasi dan server menggunakan enkripsi HTTPS/TLS 1.3.
- Kata sandi disimpan dalam bentuk hash (bcrypt), tidak pernah dalam bentuk teks biasa.
- Sesi masuk (token JWT) disimpan pada penyimpanan aman sistem operasi (Encrypted SharedPreferences pada Android, Keychain pada iOS).
- Integritas berkas bukti kegiatan diverifikasi menggunakan checksum SHA-256.
- Akses ke data di sisi server dibatasi berdasarkan peran (role-based access control) dan dicatat dalam jejak audit (audit trail).

Meskipun kami menerapkan langkah-langkah keamanan yang wajar, tidak ada sistem elektronik yang sepenuhnya bebas risiko. Kami akan memberi tahu Anda dan/atau instansi Anda sesuai kewajiban hukum yang berlaku apabila terjadi insiden keamanan data yang berdampak signifikan.

## 6. Penyimpanan dan Retensi Data

Data Anda disimpan selama akun Anda aktif dan selama diperlukan untuk memenuhi tujuan yang dijelaskan dalam kebijakan ini, termasuk kewajiban penyimpanan dokumen akuntabilitas instansi pemerintah sesuai peraturan kearsipan yang berlaku. `[Instansi pengelola Tulap.id agar melengkapi masa retensi spesifik sesuai kebijakan kearsipan yang berlaku, mis. sesuai jadwal retensi arsip instansi pemerintah.]`

## 7. Hak Anda

Sesuai UU No. 27 Tahun 2022 tentang Pelindungan Data Pribadi, Anda berhak untuk:
- Mengakses dan meminta salinan data pribadi Anda yang kami simpan.
- Meminta perbaikan data yang tidak akurat (melalui menu "Edit Profil" atau menghubungi Admin instansi Anda).
- Meminta penghapusan data pribadi Anda, sepanjang tidak bertentangan dengan kewajiban penyimpanan dokumen akuntabilitas/kearsipan instansi Anda.
- Menarik persetujuan penggunaan data tertentu (mis. mencabut izin lokasi/kamera), dengan konsekuensi sebagian fitur tidak dapat digunakan.
- Mengajukan keberatan atas pemrosesan data tertentu.

Permintaan terkait hak-hak di atas dapat diajukan melalui **support@tulap.id** atau melalui Admin instansi Anda.

## 8. Privasi Anak

Layanan ini ditujukan untuk pegawai instansi yang telah berusia dewasa dan bekerja secara sah, dan tidak ditujukan untuk anak-anak di bawah usia yang ditetapkan peraturan perundang-undangan yang berlaku. Kami tidak secara sadar mengumpulkan data pribadi anak-anak.

## 9. Perubahan Kebijakan Privasi

Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Perubahan signifikan akan diinformasikan melalui aplikasi dan/atau email terdaftar Anda. Tanggal "Terakhir diperbarui" di bagian atas dokumen ini akan selalu mencerminkan versi terbaru.

## 10. Kontak

Jika Anda memiliki pertanyaan, keluhan, atau permintaan terkait Kebijakan Privasi ini atau data pribadi Anda, silakan hubungi:

**Email**: support@tulap.id
**Operator Layanan**: Nels Folk / Nels Folk Family
