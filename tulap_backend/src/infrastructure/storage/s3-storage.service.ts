import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';

/// Masa berlaku default URL baca bertanda tangan (presigned GET).
const DEFAULT_SIGNED_URL_TTL_SECONDS = 15 * 60;

/// S3StorageService
/// ----------------------------------------------------------------------
/// Adapter tunggal ke Object Storage S3-compatible (GCP/AWS Region
/// Jakarta), sesuai kepatuhan UU PDP No. 27/2022 - data fisik foto &
/// nota WAJIB tersimpan di wilayah Indonesia.
///
/// Modul bisnis (EvidenceService, dsb) TIDAK PERNAH memanggil SDK S3
/// secara langsung - selalu lewat service ini. Ini memudahkan
/// penggantian provider storage di masa depan tanpa menyentuh business
/// logic sama sekali (prinsip Clean Architecture: infrastructure
/// terpisah dari domain/application).
/// ----------------------------------------------------------------------
@Injectable()
export class S3StorageService {
  private readonly logger = new Logger(S3StorageService.name);
  private readonly client: S3Client;
  private readonly bucketName: string;
  private readonly publicUrlBase: string;

  /// Client KHUSUS penandatanganan URL baca. Signature S3 v4 mengikat
  /// header Host, sehingga URL harus ditandatangani untuk host yang
  /// benar-benar dipanggil HP/browser (mis. https://storage.tulap.id di
  /// belakang Caddy), BUKAN S3_ENDPOINT internal backend (localhost:9000).
  /// Tidak ada request jaringan - presign murni komputasi lokal.
  private readonly signingClient: S3Client;

  constructor(private readonly configService: ConfigService) {
    this.bucketName = this.configService.get<string>('S3_BUCKET_NAME')!;
    this.publicUrlBase = this.configService.get<string>('S3_PUBLIC_URL_BASE')!;

    const region = this.configService.get<string>('S3_REGION', 'ap-southeast-3'); // Jakarta
    const credentials = {
      accessKeyId: this.configService.get<string>('S3_ACCESS_KEY')!,
      secretAccessKey: this.configService.get<string>('S3_SECRET_KEY')!,
    };

    this.client = new S3Client({
      endpoint: this.configService.get<string>('S3_ENDPOINT'),
      region,
      credentials,
      forcePathStyle: true, // Kompatibel dengan provider S3-compatible non-AWS
    });

    // Default: origin dari S3_PUBLIC_URL_BASE (format `<origin>/<bucket>`).
    // S3_SIGNING_ENDPOINT hanya perlu diisi jika URL publik memakai
    // prefix path lain di depan nama bucket.
    const signingEndpoint =
      this.configService.get<string>('S3_SIGNING_ENDPOINT') ||
      this._originOf(this.publicUrlBase);
    this.signingClient = new S3Client({
      endpoint: signingEndpoint,
      region,
      credentials,
      forcePathStyle: true,
    });
  }

  /// URL baca bertanda tangan (presigned GET) berumur pendek untuk satu
  /// objek - jalur akses file yang tetap berfungsi setelah anonymous read
  /// bucket dicabut (P0-07). JANGAN disimpan permanen oleh client:
  /// kedaluwarsa setelah `expiresInSeconds`.
  async getSignedReadUrl(
    key: string,
    expiresInSeconds = DEFAULT_SIGNED_URL_TTL_SECONDS,
  ): Promise<string> {
    return getSignedUrl(
      this.signingClient,
      new GetObjectCommand({ Bucket: this.bucketName, Key: key }),
      { expiresIn: expiresInSeconds },
    );
  }

  /// Menandatangani URL yang TERSIMPAN di database (photoUrl, scanUrl,
  /// dst). `null` jika URL tsb bukan objek bucket ini (path lokal device,
  /// URL Google, string kosong) - pemanggil lalu memakai URL lama apa
  /// adanya.
  async signStoredUrl(url: string | null | undefined): Promise<string | null> {
    const key = this.keyFromStoredUrl(url);
    return key ? this.getSignedReadUrl(key) : null;
  }

  /// Versi LONGGAR dari keyFromUrl, KHUSUS untuk penandatanganan baca:
  /// mencocokkan path `/<bucket>/<key>` tanpa mempedulikan host, karena
  /// URL lama di database bisa memakai host berbeda (IP LAN dev yang
  /// sudah berganti, atau domain lama). Aman: hanya menghasilkan key di
  /// bucket milik kita sendiri. JANGAN dipakai untuk deleteFile - jalur
  /// hapus tetap memakai keyFromUrl yang ketat.
  keyFromStoredUrl(url: string | null | undefined): string | null {
    if (!url || !/^https?:\/\//i.test(url)) return null;
    let pathname: string;
    try {
      pathname = new URL(url).pathname;
    } catch {
      return null;
    }
    const prefix = `/${this.bucketName}/`;
    if (!pathname.startsWith(prefix)) return null;
    const key = decodeURIComponent(pathname.slice(prefix.length));
    return key.length > 0 ? key : null;
  }

  private _originOf(url: string): string | undefined {
    try {
      return new URL(url).origin;
    } catch {
      return undefined;
    }
  }

  /// Mengunggah buffer file ke storage dengan path terstruktur per
  /// jenis bukti & tanggal, agar mudah di-browse manual jika perlu
  /// (mis. audit manual oleh Inspektorat) dan mudah diberi lifecycle
  /// policy retensi per kategori di kemudian hari.
  ///
  /// Contoh path hasil: evidence/photo/2026/08/10/<uuid>.jpg
  async uploadFile(params: {
    buffer: Buffer;
    mimeType: string;
    category: 'photo' | 'receipt' | 'video' | 'report' | 'avatar';
    originalFilename?: string;
  }): Promise<{ key: string; url: string }> {
    const now = new Date();
    const datePath = `${now.getFullYear()}/${String(now.getMonth() + 1).padStart(2, '0')}/${String(now.getDate()).padStart(2, '0')}`;
    const extension = this._extensionFromMimeType(params.mimeType);
    // 'avatar' bukan bukti kegiatan lapangan (evidence) - taruh di root
    // folder terpisah, bukan di bawah 'evidence/' seperti photo/receipt/dll.
    const key =
      params.category === 'avatar'
        ? `avatar/${datePath}/${randomUUID()}${extension}`
        : `evidence/${params.category}/${datePath}/${randomUUID()}${extension}`;

    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucketName,
        Key: key,
        Body: params.buffer,
        ContentType: params.mimeType,
      }),
    );

    this.logger.log(`File berhasil diunggah: ${key}`);

    return {
      key,
      url: `${this.publicUrlBase}/${key}`,
    };
  }

  /// Mengekstrak `key` dari sebuah URL publik yang dihasilkan service ini
  /// sendiri (`uploadFile().url`) - `null` jika bukan URL dari bucket ini
  /// (mis. URL foto Google/Facebook, atau path lokal device dari versi
  /// app lama), supaya pemanggil TIDAK PERNAH salah mengirim
  /// `deleteFile()` untuk resource yang bukan milik bucket kita.
  keyFromUrl(url: string | null | undefined): string | null {
    if (!url || !url.startsWith(`${this.publicUrlBase}/`)) return null;
    return url.slice(this.publicUrlBase.length + 1);
  }

  async deleteFile(key: string): Promise<void> {
    await this.client.send(
      new DeleteObjectCommand({ Bucket: this.bucketName, Key: key }),
    );
  }

  private _extensionFromMimeType(mimeType: string): string {
    switch (mimeType) {
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'video/mp4':
        return '.mp4';
      case 'video/quicktime':
        return '.mov';
      default:
        return '';
    }
  }
}
