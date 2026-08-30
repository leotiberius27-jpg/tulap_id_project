import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';

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

  constructor(private readonly configService: ConfigService) {
    this.bucketName = this.configService.get<string>('S3_BUCKET_NAME')!;
    this.publicUrlBase = this.configService.get<string>('S3_PUBLIC_URL_BASE')!;

    this.client = new S3Client({
      endpoint: this.configService.get<string>('S3_ENDPOINT'),
      region: this.configService.get<string>('S3_REGION', 'ap-southeast-3'), // Jakarta
      credentials: {
        accessKeyId: this.configService.get<string>('S3_ACCESS_KEY')!,
        secretAccessKey: this.configService.get<string>('S3_SECRET_KEY')!,
      },
      forcePathStyle: true, // Kompatibel dengan provider S3-compatible non-AWS
    });
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
    category: 'photo' | 'receipt' | 'video' | 'report';
    originalFilename?: string;
  }): Promise<{ key: string; url: string }> {
    const now = new Date();
    const datePath = `${now.getFullYear()}/${String(now.getMonth() + 1).padStart(2, '0')}/${String(now.getDate()).padStart(2, '0')}`;
    const extension = this._extensionFromMimeType(params.mimeType);
    const key = `evidence/${params.category}/${datePath}/${randomUUID()}${extension}`;

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
