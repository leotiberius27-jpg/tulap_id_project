# Panduan Setup MinIO Tulap.id di Biznet Gio

Panduan ini untuk memasang instance MinIO **khusus Tulap.id** (terpisah dari MinIO milik FINO) di server Biznet Gio NEO Lite Pro Anda yang sudah ada, memakai `tulap_backend/docker-compose-minio.yml`.

> **Status**: sudah pernah dijalankan sukses end-to-end di `fino-production` pada 2026-09-20 - `docker-compose-minio.yml` dan `Caddyfile` di repo ini sudah memuat semua perbaikan yang ditemukan saat itu (image `quay.io/minio/minio`, `MINIO_ROOT_USER_FILE`/`PASSWORD_FILE` dikosongkan paksa, `auto_https disable_redirects` karena port 80 dipakai FINO). Panduan di bawah tetap berlaku penuh kalau suatu saat perlu dipasang ulang dari nol di server lain.

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

## 8. Pasang Caddy - domain publik + HTTPS untuk MinIO API

**Kenapa ini wajib, bukan opsional**: domain Tailscale (`fino-production.tailf5234a.ts.net`) cuma bisa diakses perangkat yang ikut tailnet pribadi Anda. Backend di Railway BUKAN bagian dari tailnet itu, dan **HP pegawai lapangan yang pakai aplikasi Tulap.id juga bukan** — jadi kalau endpoint API tetap di domain Tailscale, foto bukti kegiatan tidak akan tampil untuk siapa pun di luar tailnet Anda. Solusinya: satu reverse proxy publik (Caddy, otomatis HTTPS gratis lewat Let's Encrypt) di depan MinIO, cuma untuk port API (9000) — Console (9001) tetap Tailscale-only untuk keamanan.

File konfigurasinya sudah ada di repo: `tulap_backend/Caddyfile`.

```bash
# Di server, install Caddy (Ubuntu/Debian):
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy

# Salin isi tulap_backend/Caddyfile (dari repo ini) ke server:
sudo nano /etc/caddy/Caddyfile
# tempel isinya, simpan (Ctrl+O, Enter, Ctrl+X)

# Buka firewall untuk HTTPS (kalau ufw aktif):
sudo ufw allow 443/tcp

# Start Caddy:
sudo systemctl enable caddy
sudo systemctl restart caddy
sudo systemctl status caddy   # pastikan "active (running)"
```

**Kalau server Anda juga menjalankan aplikasi lain yang sudah memakai port 80** (seperti FINO di sini - `fino_frontend` sudah bind ke port 80) - Caddy akan **gagal start total** dengan error `listen tcp :80: bind: address already in use`, karena secara default Caddy juga mencoba bind port 80 untuk redirect HTTP→HTTPS otomatis. Isi `Caddyfile` di repo ini **sudah** menyertakan blok berikut untuk menghindarinya - sertifikat tetap didapat otomatis lewat tantangan TLS-ALPN-01 di port 443 saja:
```
{
	auto_https disable_redirects
}
```

Caddy otomatis mengurus sertifikat HTTPS begitu DNS `storage.tulap.id` sudah mengarah ke IP publik server ini (Langkah 9) dan port 443 terbuka ke internet - dicoba ulang otomatis tiap 60 detik kalau gagal (mis. DNS belum propagasi), tidak perlu restart manual.

## 9. Arahkan DNS `storage.tulap.id` ke IP publik server

Tambahkan **A Record** di DNS management domain `tulap.id` Anda (mis. Cloudflare):

| Type | Name | Value | Proxy status |
|---|---|---|---|
| A | `storage` | *(IP publik server Biznet Gio - lihat catatan di bawah)* | **DNS only** (bukan "Proxied"/awan oranye - Caddy butuh koneksi langsung untuk validasi HTTPS) |

**Cara pasti dapat IP publiknya**: jalankan ini langsung di server (lewat SSH Anda):
```bash
curl -4 ifconfig.me
```
Pakai hasil itu sebagai Value A Record di atas - jangan tebak dari sumber lain, IP publik server bisa beda dari yang terlihat di tools pihak ketiga.

Untuk `fino-production` (server yang sama dipakai sesi 2026-09-20 ini): `103.94.238.71`.

## 10. Kirim info berikut untuk disambungkan ke Railway

Setelah Langkah 1-9 selesai, kirim 4 hal ini (endpoint publiknya sudah tetap, tidak perlu dikirim ulang):

| Variabel | Nilai |
|---|---|
| `S3_ENDPOINT` | `https://storage.tulap.id` |
| `S3_PUBLIC_URL_BASE` | `https://storage.tulap.id/tulap-storage-prod` |
| `S3_ACCESS_KEY` | *(dari Langkah 7)* |
| `S3_SECRET_KEY` | *(dari Langkah 7)* |

`S3_BUCKET_NAME` sudah pasti `tulap-storage-prod` (Langkah 5), tidak perlu dikirim ulang.
