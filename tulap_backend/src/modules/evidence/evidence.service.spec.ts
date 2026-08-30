import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { EvidenceService } from './evidence.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuditService } from '../audit/audit.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { createHash } from 'crypto';

describe('EvidenceService', () => {
  let service: EvidenceService;
  let prisma: any;
  let storage: any;
  let audit: any;

  const mockUser: AuthenticatedUser = {
    id: 'user_1',
    email: 'budi@tulap.id',
    fullName: 'Budi Santoso',
    role: 'PEGAWAI',
    instansiName: 'Dinas PU',
  };

  beforeEach(async () => {
    prisma = {
      task_SPPD: {
        findUnique: jest.fn(),
      },
      geotag_Photo: {
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        create: jest.fn(),
        delete: jest.fn(),
      },
      expense_Note: {
        findFirst: jest.fn(),
        create: jest.fn(),
      },
    };

    storage = {
      uploadFile: jest.fn().mockResolvedValue({
        key: 'evidence/photo/2026/08/26/test.jpg',
        url: 'https://storage.tulap.id/evidence/photo/2026/08/26/test.jpg',
      }),
    };

    audit = {
      log: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EvidenceService,
        { provide: PrismaService, useValue: prisma },
        { provide: S3StorageService, useValue: storage },
        { provide: AuditService, useValue: audit },
      ],
    }).compile();

    service = module.get<EvidenceService>(EvidenceService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('uploadPhoto', () => {
    it('should throw NotFoundException if task does not exist', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue(null);

      const fakeFile = {
        buffer: Buffer.from('test_image_data'),
        mimetype: 'image/jpeg',
      } as Express.Multer.File;

      await expect(
        service.uploadPhoto(
          {
            taskId: 'non_existent_task',
            latitude: -6.2,
            longitude: 106.8,
            gpsAccuracyMeters: 5.0,
            serverTimestamp: new Date().toISOString(),
            integrityHash: 'some_hash',
            isMockLocationDetected: false,
            isRootedDeviceDetected: false,
          },
          fakeFile,
          mockUser,
        ),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException if task assigned to different user', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue({
        id: 'task_1',
        assigneeId: 'different_user',
      });

      const fakeFile = {
        buffer: Buffer.from('test_image_data'),
        mimetype: 'image/jpeg',
      } as Express.Multer.File;

      await expect(
        service.uploadPhoto(
          {
            taskId: 'task_1',
            latitude: -6.2,
            longitude: 106.8,
            gpsAccuracyMeters: 5.0,
            serverTimestamp: new Date().toISOString(),
            integrityHash: 'some_hash',
            isMockLocationDetected: false,
            isRootedDeviceDetected: false,
          },
          fakeFile,
          mockUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should successfully upload photo and record audit trail', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue({
        id: 'task_1',
        assigneeId: 'user_1',
      });

      const buffer = Buffer.from('image_bytes');
      const hash = createHash('sha256').update(buffer).digest('hex');

      const fakeFile = {
        buffer,
        mimetype: 'image/jpeg',
      } as Express.Multer.File;

      prisma.geotag_Photo.create.mockResolvedValue({
        id: 'photo_1',
        photoUrl: 'https://storage.tulap.id/evidence/photo/2026/08/26/test.jpg',
      });

      const result = await service.uploadPhoto(
        {
          taskId: 'task_1',
          latitude: -2.53,
          longitude: 140.71,
          gpsAccuracyMeters: 4.2,
          address: 'Jl. Ahmad Yani, Jayapura',
          serverTimestamp: new Date().toISOString(),
          integrityHash: hash,
          isMockLocationDetected: false,
          isRootedDeviceDetected: false,
        },
        fakeFile,
        mockUser,
      );

      expect(result).toHaveProperty('id');
      expect(result.hashVerified).toBe(true);
      expect(storage.uploadFile).toHaveBeenCalled();
      expect(audit.log).toHaveBeenCalled();
    });
  });

  describe('uploadReceipt', () => {
    it('should successfully upload receipt with idempotency and audit log', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue({
        id: 'task_1',
        assigneeId: 'user_1',
      });
      prisma.expense_Note.findUnique = jest.fn().mockResolvedValue(null);
      prisma.expense_Note.findFirst.mockResolvedValue(null);
      prisma.expense_Note.create.mockResolvedValue({
        id: 'receipt_1',
        scanUrl: 'https://storage.tulap.id/evidence/receipt/test.jpg',
        verificationStatus: 'PENDING',
      });

      const fakeFile = {
        buffer: Buffer.from('receipt_image_bytes'),
        mimetype: 'image/jpeg',
      } as Express.Multer.File;

      const result = await service.uploadReceipt(
        {
          id: 'receipt_1',
          taskId: 'task_1',
          vendorName: 'SPBU Pertamina 84.999.01',
          transactionDate: new Date().toISOString(),
          totalAmount: 450000,
          category: 'bbm',
        },
        fakeFile,
        mockUser,
      );

      expect(result).toHaveProperty('id', 'receipt_1');
      expect(prisma.expense_Note.create).toHaveBeenCalled();
      expect(audit.log).toHaveBeenCalled();
    });
  });
});
