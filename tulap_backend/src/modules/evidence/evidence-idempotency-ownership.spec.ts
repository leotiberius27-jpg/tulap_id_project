import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException } from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { EvidenceService } from './evidence.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuditService } from '../audit/audit.service';
import { FirestoreSyncService } from '../../infrastructure/firestore/firestore-sync.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { UploadPhotoDto } from './dto/upload-photo.dto';
import { UploadReceiptDto } from './dto/upload-receipt.dto';

/// Regression test P0-06: jalur idempotensi `id` dari client. Sebelum
/// perbaikan, user B yang mengirim `id` milik foto/nota user A (di tugas
/// B sendiri) menerima photoUrl/scanUrl milik A tanpa pemeriksaan.
describe('EvidenceService - kepemilikan pada idempotensi upload', () => {
  let service: EvidenceService;
  let prisma: any;
  let storage: any;
  let audit: any;

  const userA: AuthenticatedUser = {
    id: 'pegawai_a', email: 'a@tulap.id', fullName: 'A', role: RoleName.PEGAWAI, instansiName: 'Dinas PU',
  };
  const userB: AuthenticatedUser = { ...userA, id: 'pegawai_b', email: 'b@tulap.id', fullName: 'B' };

  const photoMilikA = {
    id: 'photo-a',
    taskId: 'task-a',
    uploaderId: userA.id,
    photoUrl: 'https://storage.tulap.id/evidence/photo/RAHASIA-A.jpg',
    serverTimestamp: new Date('2026-10-13T09:00:00Z'),
  };
  const notaMilikA = {
    id: 'note-a',
    taskId: 'task-a',
    ownerId: userA.id,
    scanUrl: 'https://storage.tulap.id/evidence/receipt/RAHASIA-A.jpg',
    verificationStatus: 'PENDING',
    createdAt: new Date('2026-10-13T09:00:00Z'),
  };

  const photoDto = (actorTaskId: string, id = 'photo-a'): UploadPhotoDto => ({
    id,
    taskId: actorTaskId,
    latitude: -4.54,
    longitude: 136.87,
    gpsAccuracyMeters: 8,
    serverTimestamp: '2026-10-13T09:00:00Z',
    integrityHash: 'a'.repeat(64),
    isMockLocationDetected: false,
    isRootedDeviceDetected: false,
  });

  const receiptDto = (actorTaskId: string, id = 'note-a'): UploadReceiptDto => ({
    id,
    taskId: actorTaskId,
    vendorName: 'SPBU 34.123',
    transactionDate: '2026-10-13',
    totalAmount: 150000,
    category: 'bbm',
  });

  const file = { buffer: Buffer.from('jpg'), mimetype: 'image/jpeg' } as Express.Multer.File;

  beforeEach(async () => {
    prisma = {
      // Setiap user adalah assignee tugasnya sendiri: task-a milik A, task-b milik B.
      task_SPPD: {
        findUnique: jest.fn(({ where }) =>
          Promise.resolve({ id: where.id, assigneeId: where.id === 'task-a' ? userA.id : userB.id }),
        ),
      },
      geotag_Photo: {
        findUnique: jest.fn().mockResolvedValue(photoMilikA),
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn(),
      },
      expense_Note: {
        findUnique: jest.fn().mockResolvedValue(notaMilikA),
        findFirst: jest.fn().mockResolvedValue(null),
        create: jest.fn(),
      },
    };
    storage = { uploadFile: jest.fn() };
    audit = { log: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EvidenceService,
        { provide: PrismaService, useValue: prisma },
        { provide: S3StorageService, useValue: storage },
        { provide: AuditService, useValue: audit },
        { provide: FirestoreSyncService, useValue: { mirrorAssetDocument: jest.fn() } },
      ],
    }).compile();

    service = module.get(EvidenceService);
  });

  const expectNoWrites = () => {
    expect(storage.uploadFile).not.toHaveBeenCalled();
    expect(prisma.geotag_Photo.create).not.toHaveBeenCalled();
    expect(prisma.expense_Note.create).not.toHaveBeenCalled();
    expect(audit.log).not.toHaveBeenCalled();
  };

  describe('uploadPhoto', () => {
    it('user lain memakai id foto milik A di tugasnya sendiri -> 409 tanpa photoUrl A', async () => {
      const call = service.uploadPhoto(photoDto('task-b'), file, userB);
      await expect(call).rejects.toThrow(ConflictException);
      await call.catch((e) => expect(JSON.stringify(e.getResponse())).not.toContain('RAHASIA-A'));
      expectNoWrites();
    });

    it('pemilik yang sama tetapi tugas berbeda -> 409', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue({ id: 'task-a2', assigneeId: userA.id });
      await expect(service.uploadPhoto(photoDto('task-a2'), file, userA)).rejects.toThrow(
        ConflictException,
      );
      expectNoWrites();
    });

    it('retry oleh pemilik yang sama untuk tugas yang sama tetap idempoten', async () => {
      await expect(service.uploadPhoto(photoDto('task-a'), file, userA)).resolves.toEqual({
        id: 'photo-a',
        photoUrl: photoMilikA.photoUrl,
        serverTimestamp: photoMilikA.serverTimestamp.toISOString(),
        hashVerified: true,
      });
      expectNoWrites();
    });
  });

  describe('uploadReceipt', () => {
    it('user lain memakai id nota milik A di tugasnya sendiri -> 409 tanpa scanUrl A', async () => {
      const call = service.uploadReceipt(receiptDto('task-b'), file, userB);
      await expect(call).rejects.toThrow(ConflictException);
      await call.catch((e) => expect(JSON.stringify(e.getResponse())).not.toContain('RAHASIA-A'));
      expectNoWrites();
    });

    it('pemilik yang sama tetapi tugas berbeda -> 409', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue({ id: 'task-a2', assigneeId: userA.id });
      await expect(service.uploadReceipt(receiptDto('task-a2'), file, userA)).rejects.toThrow(
        ConflictException,
      );
      expectNoWrites();
    });

    it('retry oleh pemilik yang sama untuk tugas yang sama tetap idempoten', async () => {
      await expect(service.uploadReceipt(receiptDto('task-a'), file, userA)).resolves.toEqual({
        id: 'note-a',
        scanUrl: notaMilikA.scanUrl,
        verificationStatus: 'PENDING',
        serverTimestamp: notaMilikA.createdAt.toISOString(),
      });
      expectNoWrites();
    });
  });
});
