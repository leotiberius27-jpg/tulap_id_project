import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException } from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { EvidenceService } from './evidence.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuditService } from '../audit/audit.service';
import { FirestoreSyncService } from '../../infrastructure/firestore/firestore-sync.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';

/// P0-07: GET /evidence/photo/:id & /evidence/receipt/:id menambahkan URL
/// bertanda tangan (aditif) - dan HANYA setelah pemeriksaan akses yang
/// sama seperti sebelumnya lolos.
describe('EvidenceService - URL bertanda tangan untuk client (P0-07)', () => {
  let service: EvidenceService;
  let prisma: any;
  let storage: any;

  const owner: AuthenticatedUser = {
    id: 'pegawai_a', email: 'a@tulap.id', fullName: 'A', role: RoleName.PEGAWAI, instansiName: 'Dinas PU',
  };
  const other: AuthenticatedUser = { ...owner, id: 'pegawai_b' };

  const photoUrl = 'https://storage.tulap.id/tulap-storage-prod/evidence/photo/a.jpg';
  const scanUrl = 'https://storage.tulap.id/tulap-storage-prod/evidence/receipt/n.jpg';

  beforeEach(async () => {
    prisma = {
      geotag_Photo: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'photo-1', taskId: 'task-1', uploaderId: owner.id, photoUrl,
          task: { assigneeId: owner.id }, uploader: {},
        }),
      },
      expense_Note: {
        findUnique: jest.fn().mockResolvedValue({ id: 'note-1', ownerId: owner.id, scanUrl, task: {}, owner: {} }),
      },
    };
    storage = { signStoredUrl: jest.fn(async (u: string) => `${u}?X-Amz-Signature=sig`) };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EvidenceService,
        { provide: PrismaService, useValue: prisma },
        { provide: S3StorageService, useValue: storage },
        { provide: AuditService, useValue: { log: jest.fn() } },
        { provide: FirestoreSyncService, useValue: { mirrorAssetDocument: jest.fn() } },
      ],
    }).compile();
    service = module.get(EvidenceService);
  });

  it('foto: field lama tetap ada + photoSignedUrl ditambahkan', async () => {
    const result = await service.getEvidencePhotoForClient('photo-1', owner);
    expect(result.photoUrl).toBe(photoUrl);
    expect(result.photoSignedUrl).toBe(`${photoUrl}?X-Amz-Signature=sig`);
  });

  it('nota: field lama tetap ada + scanSignedUrl ditambahkan', async () => {
    const result = await service.getEvidenceReceiptForClient('note-1', owner);
    expect(result.scanUrl).toBe(scanUrl);
    expect(result.scanSignedUrl).toBe(`${scanUrl}?X-Amz-Signature=sig`);
  });

  it('akses ditolak -> tidak ada URL bertanda tangan yang dibuat', async () => {
    await expect(service.getEvidencePhotoForClient('photo-1', other)).rejects.toThrow(ForbiddenException);
    await expect(service.getEvidenceReceiptForClient('note-1', other)).rejects.toThrow(ForbiddenException);
    expect(storage.signStoredUrl).not.toHaveBeenCalled();
  });
});
