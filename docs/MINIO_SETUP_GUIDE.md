# Panduan Setup MinIO Tulap.id di Biznet Gio

Panduan ini untuk memasang instance MinIO **khusus Tulap.id** (terpisah dari MinIO milik FINO) di server Biznet Gio NEO Lite Pro Anda yang sudah ada, memakai `tulap_backend/docker-compose-minio.yml`.

## 0. Sebelum mulai

- [ ] Server Biznet Gio Anda sudah tersambung ke tailnet yang sama dengan domain `fino-production.tailf5234a.ts.net` (cek dengan `tailscale status` di server).
- [ ] Docker & Docker Compose sudah terpasang di server (karena FINO sudah jalan di sana, kemungkinan besar sudah ada).
- [ ] Port **9000** dan **9001** belum dipakai container lain (cek dengan `docker ps` dan `ss -tulpn | grep -E ':900[01]'`).

## 1. Masuk ke server lewat Open Console / SSH

```bash
ssh <user_anda>@<ip_atau_host_biznet_gio>
```

## 2. Salin `docker-compose-minio.yml` ke server

Cara termudah: buat foldernya dulu, lalu tempel isi file dari `tulap_backend/docker-compose-minio.yml` (di repo ini) ke server pakai editor `nano`.

```bash
mkdir -p ~/tulap-minio && cd ~/tulap-minio
nano docker-compose-minio.yml
```

Tempel seluruh isi file, lalu simpan (`Ctrl+O`, Enter, `Ctrl+X` di nano).

**WAJIB diubah sebelum lanjut**: buka lagi filenya dan ganti dua baris ini dengan nilai Anda sendiri (jangan pakai contoh):

```yaml
MINIO_ROOT_USER: "GANTI_DENGAN_USERNAME_ROOT_ANDA"
MINIO_ROOT_PASSWORD: "GANTI_DENGAN_PASSWORD_ROOT_MINIMAL_8_KARAKTER"
```

## 3. Jalankan MinIO

```bash
docker compose -f docker-compose-minio.yml up -d
docker compose -f docker-compose-minio.yml ps   # pastikan status "healthy"
```

## 4. Buka MinIO Console lewat Tailscale

Dari browser komputer mana pun yang **juga tersambung ke tailnet yang sama**:

```
http://fino-production.tailf5234a.ts.net:9001
```

Login pakai `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` yang Anda set di Langkah 2.

## 5. Buat bucket `tulap-storage-prod`

Di MinIO Console:
1. Menu **Buckets** (sidebar kiri) → **Create Bucket**
2. Nama: `tulap-storage-prod` → **Create Bucket**

## 6. Set akses bucket ke Public

1. Buka bucket `tulap-storage-prod` yang baru dibuat → tab **Access Rules** (atau **Anonymous Access** tergantung versi Console)
2. **Add Access Rule** → Prefix: `*` (semua isi bucket) → Access: **readonly** (public read, BUKAN write - supaya orang luar tidak bisa upload/hapus)
3. Simpan

Alternatif lewat CLI `mc` (kalau Console-nya beda tampilan dari yang di atas), jalankan di server:
```bash
docker exec -it tulap-minio-prod mc alias set local http://localhost:9000 <MINIO_ROOT_USER> <MINIO_ROOT_PASSWORD>
docker exec -it tulap-minio-prod mc anonymous set download local/tulap-storage-prod
```

## 7. Buat Access Key khusus backend (jangan pakai root)

1. Di Console: menu **Access Keys** (sidebar kiri, di bawah **Identity**) → **Create access key**
2. Biarkan expiry kosong (tidak kedaluwarsa) kecuali Anda ingin rotasi berkala
3. **Create** → **salin & simpan Access Key dan Secret Key yang muncul** (hanya ditampilkan sekali)

## 8. ⚠️ WAJIB dicek: HTTP vs HTTPS

Domain Tailscale di atas dipakai dengan `http://` (bukan `https://`). Ini **cukup untuk testing**, tapi:

- **Android release build (APK/AAB) memblokir traffic HTTP polos secara default** — kalau endpoint ini tetap `http://` saat rilis ke Play Store, foto tidak akan bisa tampil di aplikasi pengguna.
- Solusi: aktifkan HTTPS Tailscale untuk mesin ini (`tailscale cert fino-production.tailf5234a.ts.net` di server, perlu HTTPS diaktifkan dulu di [Tailscale Admin Console](https://login.tailscale.com/admin/dns) → DNS → "Enable HTTPS Certificates"), lalu pasang reverse proxy (Caddy/Nginx) di depan MinIO yang memakai sertifikat tsb, forward ke port 9000 lokal.
- Kalau FINO sudah punya pola reverse proxy + HTTPS yang sama, pola itu bisa ditiru persis untuk MinIO Tulap.id ini.

**Untuk tahap development/testing sekarang, `http://` di atas sudah cukup untuk dites lewat `flutter run` di HP fisik via USB/adb** (bukan APK rilis) — jadi tidak menghalangi pengujian, tapi jangan lupa dibereskan sebelum submit ke Play Store.

## 9. Kirim info berikut untuk disambungkan ke Railway

Setelah semua langkah di atas selesai, kirim 5 hal ini:

| Variabel | Nilai |
|---|---|
| `S3_ENDPOINT` | `http://fino-production.tailf5234a.ts.net:9000` |
| `S3_PUBLIC_URL_BASE` | `http://fino-production.tailf5234a.ts.net:9000/tulap-storage-prod` |
| `S3_BUCKET_NAME` | `tulap-storage-prod` |
| `S3_ACCESS_KEY` | *(dari Langkah 7)* |
| `S3_SECRET_KEY` | *(dari Langkah 7)* |

Catatan: karena endpoint ini adalah domain Tailscale (jaringan privat), backend di Railway **tidak otomatis bisa menjangkaunya** — Railway bukan bagian dari tailnet Anda. Ini perlu langkah tambahan (mis. memasang Tailscale sebagai sidecar/subnet router yang bisa diakses dari Railway, atau expose endpoint ini lewat internet publik dengan cara lain) yang akan dibahas setelah info di atas diterima.
