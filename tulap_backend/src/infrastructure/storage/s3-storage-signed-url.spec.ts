import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { S3StorageService } from './s3-storage.service';

/// P0-07: URL baca bertanda tangan (presigned GET). Presign adalah
/// komputasi lokal - tidak ada request ke storage di test ini.
describe('S3StorageService - URL baca bertanda tangan (P0-07)', () => {
  const build = async (overrides: Record<string, string | undefined> = {}) => {
    const values: Record<string, string | undefined> = {
      S3_BUCKET_NAME: 'tulap-storage-prod',
      S3_PUBLIC_URL_BASE: 'https://storage.tulap.id/tulap-storage-prod',
      S3_ENDPOINT: 'http://localhost:9000',
      S3_REGION: 'ap-southeast-3',
      S3_ACCESS_KEY: 'test_access_key',
      S3_SECRET_KEY: 'test_secret_key',
      ...overrides,
    };
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        S3StorageService,
        {
          provide: ConfigService,
          useValue: { get: (key: string, def?: string) => values[key] ?? def },
        },
      ],
    }).compile();
    return module.get(S3StorageService);
  };

  describe('getSignedReadUrl', () => {
    it('ditandatangani untuk HOST PUBLIK (bukan S3_ENDPOINT internal), path-style, TTL 15 menit', async () => {
      const service = await build();
      const url = new URL(await service.getSignedReadUrl('evidence/photo/2026/10/14/a.jpg'));

      expect(url.origin).toBe('https://storage.tulap.id');
      expect(url.pathname).toBe('/tulap-storage-prod/evidence/photo/2026/10/14/a.jpg');
      expect(url.searchParams.get('X-Amz-Algorithm')).toBe('AWS4-HMAC-SHA256');
      expect(url.searchParams.get('X-Amz-Expires')).toBe('900');
      expect(url.searchParams.get('X-Amz-Signature')).toMatch(/^[0-9a-f]{64}$/);
      expect(url.searchParams.get('X-Amz-Credential')).toContain('ap-southeast-3/s3/aws4_request');
      // Secret key tidak pernah ikut di URL.
      expect(url.toString()).not.toContain('test_secret_key');
    });

    it('TTL dapat diatur per pemanggilan', async () => {
      const service = await build();
      const url = new URL(await service.getSignedReadUrl('k.jpg', 60));
      expect(url.searchParams.get('X-Amz-Expires')).toBe('60');
    });

    it('S3_SIGNING_ENDPOINT menimpa origin turunan S3_PUBLIC_URL_BASE', async () => {
      const service = await build({ S3_SIGNING_ENDPOINT: 'https://cdn.tulap.id' });
      const url = new URL(await service.getSignedReadUrl('k.jpg'));
      expect(url.origin).toBe('https://cdn.tulap.id');
    });

    it('signature berbeda untuk key berbeda (tidak bisa dipakai ulang untuk objek lain)', async () => {
      const service = await build();
      const a = new URL(await service.getSignedReadUrl('a.jpg')).searchParams.get('X-Amz-Signature');
      const b = new URL(await service.getSignedReadUrl('b.jpg')).searchParams.get('X-Amz-Signature');
      expect(a).not.toBe(b);
    });
  });

  describe('keyFromStoredUrl (longgar, khusus penandatanganan baca)', () => {
    it.each([
      ['URL publik saat ini', 'https://storage.tulap.id/tulap-storage-prod/evidence/photo/x.jpg', 'evidence/photo/x.jpg'],
      ['host lama / IP LAN dev yang sudah berganti', 'http://10.230.74.200:9000/tulap-storage-prod/evidence/receipt/y.jpg', 'evidence/receipt/y.jpg'],
      ['karakter ter-encode', 'https://storage.tulap.id/tulap-storage-prod/avatar/a%20b.jpg', 'avatar/a b.jpg'],
    ])('%s -> key', async (_l, input, expected) => {
      const service = await build();
      expect(service.keyFromStoredUrl(input)).toBe(expected);
    });

    it.each([
      ['bucket lain', 'https://storage.tulap.id/bucket-lain/x.jpg'],
      ['URL Google (foto profil OAuth)', 'https://lh3.googleusercontent.com/a/abc'],
      ['path lokal device versi app lama', '/data/user/0/id.tulap/files/x.jpg'],
      ['string kosong', ''],
      ['null', null],
      ['hanya nama bucket', 'https://storage.tulap.id/tulap-storage-prod/'],
    ])('%s -> null', async (_l, input) => {
      const service = await build();
      expect(service.keyFromStoredUrl(input as string | null)).toBeNull();
    });

    it('keyFromUrl (jalur HAPUS) tetap ketat: host lama TIDAK cocok', async () => {
      const service = await build();
      expect(
        service.keyFromUrl('http://10.230.74.200:9000/tulap-storage-prod/evidence/photo/x.jpg'),
      ).toBeNull();
    });
  });

  describe('signStoredUrl', () => {
    it('URL tersimpan milik bucket -> URL bertanda tangan untuk key yang sama', async () => {
      const service = await build();
      const signed = await service.signStoredUrl(
        'http://10.230.74.200:9000/tulap-storage-prod/evidence/photo/x.jpg',
      );
      const url = new URL(signed!);
      expect(url.origin).toBe('https://storage.tulap.id');
      expect(url.pathname).toBe('/tulap-storage-prod/evidence/photo/x.jpg');
    });

    it('URL di luar bucket -> null (client memakai URL lama apa adanya)', async () => {
      const service = await build();
      await expect(service.signStoredUrl('https://lh3.googleusercontent.com/a/abc')).resolves.toBeNull();
      await expect(service.signStoredUrl('')).resolves.toBeNull();
    });
  });
});
