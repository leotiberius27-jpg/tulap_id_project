import { Test, TestingModule } from '@nestjs/testing';
import { ConflictException } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuditService } from '../audit/audit.service';
import { TravelService } from './travel.service';
import { CreateSupportingDocumentDto } from './dto/create-supporting-document.dto';
import { CreateLpjPackageDto } from './dto/create-lpj-package.dto';

/// Regression test P0-06 (modul Travel): sebelum perbaikan, `id`
/// dokumen pendukung / paket LPJ milik perjalanan dinas user lain
/// mengembalikan record lengkapnya (documentUrl, pdfUrl, contentSnapshot)
/// - dan file yang ikut dikirim tetap diunggah ke storage lalu dibuang.
describe('TravelService - kepemilikan pada idempotensi upload', () => {
  let service: TravelService;
  let prisma: any;
  let storage: any;
  let audit: any;

  const missionB = { id: 'mission-b', userId: 'user-b' };

  const docMilikA = {
    id: 'doc-a',
    travelMissionId: 'mission-a',
    documentUrl: 'https://storage.tulap.id/evidence/report/RAHASIA-A.pdf',
    sha256: 'a'.repeat(64),
  };
  const pkgMilikA = {
    id: 'pkg-a',
    travelMissionId: 'mission-a',
    pdfUrl: 'https://storage.tulap.id/evidence/report/RAHASIA-A-LPJ.pdf',
    contentSnapshot: { rahasia: true },
  };

  const file = {
    buffer: Buffer.from('%PDF'),
    mimetype: 'application/pdf',
    originalname: 'x.pdf',
  } as Express.Multer.File;

  beforeEach(async () => {
    prisma = {
      travel_Mission: { findUnique: jest.fn().mockResolvedValue(missionB) },
      supporting_Document: { findUnique: jest.fn(), create: jest.fn() },
      lPJ_Package: { findUnique: jest.fn(), create: jest.fn() },
    };
    storage = {
      uploadFile: jest.fn().mockResolvedValue({ key: 'k', url: 'https://storage.tulap.id/k' }),
    };
    audit = { log: jest.fn() };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TravelService,
        { provide: PrismaService, useValue: prisma },
        { provide: S3StorageService, useValue: storage },
        { provide: AuditService, useValue: audit },
      ],
    }).compile();

    service = module.get(TravelService);
  });

  const docDto = { id: 'doc-a', travelMissionId: 'mission-b' } as CreateSupportingDocumentDto;
  const pkgDto = { id: 'pkg-a', travelMissionId: 'mission-b' } as CreateLpjPackageDto;

  describe('uploadSupportingDocument', () => {
    it('id dokumen milik perjalanan dinas user lain -> 409, data & file tidak bocor/tidak diunggah', async () => {
      prisma.supporting_Document.findUnique.mockResolvedValue(docMilikA);

      const call = service.uploadSupportingDocument('user-b', docDto, file);
      await expect(call).rejects.toThrow(ConflictException);
      await call.catch((e) => expect(JSON.stringify(e.getResponse())).not.toContain('RAHASIA-A'));
      expect(storage.uploadFile).not.toHaveBeenCalled();
      expect(prisma.supporting_Document.create).not.toHaveBeenCalled();
    });

    it('retry pemilik yang sama: record lama dikembalikan TANPA mengunggah file lagi', async () => {
      const own = { ...docMilikA, id: 'doc-b', travelMissionId: 'mission-b' };
      prisma.supporting_Document.findUnique.mockResolvedValue(own);

      await expect(
        service.uploadSupportingDocument('user-b', { ...docDto, id: 'doc-b' }, file),
      ).resolves.toBe(own);
      expect(storage.uploadFile).not.toHaveBeenCalled();
      expect(prisma.supporting_Document.create).not.toHaveBeenCalled();
    });

    it('id baru: file diunggah dan dokumen dibuat seperti biasa', async () => {
      prisma.supporting_Document.findUnique.mockResolvedValue(null);
      prisma.supporting_Document.create.mockResolvedValue({ id: 'doc-new', documentType: 'SPPD', title: 't' });

      await service.uploadSupportingDocument('user-b', { ...docDto, id: 'doc-new' }, file);
      expect(storage.uploadFile).toHaveBeenCalledTimes(1);
      expect(prisma.supporting_Document.create).toHaveBeenCalledTimes(1);
    });
  });

  describe('createOrUpdateLpjPackage', () => {
    it('id paket LPJ milik perjalanan dinas user lain -> 409, data & file tidak bocor/tidak diunggah', async () => {
      prisma.lPJ_Package.findUnique.mockResolvedValue(pkgMilikA);

      const call = service.createOrUpdateLpjPackage('user-b', pkgDto, file);
      await expect(call).rejects.toThrow(ConflictException);
      await call.catch((e) => expect(JSON.stringify(e.getResponse())).not.toContain('RAHASIA-A'));
      expect(storage.uploadFile).not.toHaveBeenCalled();
      expect(prisma.lPJ_Package.create).not.toHaveBeenCalled();
    });

    it('retry pemilik yang sama: paket lama dikembalikan TANPA mengunggah file lagi', async () => {
      const own = { ...pkgMilikA, id: 'pkg-b', travelMissionId: 'mission-b' };
      prisma.lPJ_Package.findUnique.mockResolvedValue(own);

      await expect(
        service.createOrUpdateLpjPackage('user-b', { ...pkgDto, id: 'pkg-b' }, file),
      ).resolves.toBe(own);
      expect(storage.uploadFile).not.toHaveBeenCalled();
      expect(prisma.lPJ_Package.create).not.toHaveBeenCalled();
    });
  });
});
