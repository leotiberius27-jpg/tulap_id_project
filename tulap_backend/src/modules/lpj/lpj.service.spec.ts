import { Test, TestingModule } from '@nestjs/testing';
import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { LpjService } from './lpj.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { UploadReportDto } from './dto/upload-report.dto';

/// Regression test P0-01: otorisasi endpoint laporan kegiatan
/// (/lpj/report/*). Sebelum perbaikan, user login MANA PUN dapat
/// mengunggah ke tugas orang lain, membaca laporan siapa pun, dan
/// menghapus file laporan siapa pun.
describe('LpjService - otorisasi laporan kegiatan', () => {
  let service: LpjService;
  let prisma: any;
  let s3Storage: any;
  let audit: any;

  const user = (
    id: string,
    role: RoleName,
    instansiName: string | null,
  ): AuthenticatedUser => ({
    id,
    email: `${id}@tulap.id`,
    fullName: id,
    role,
    instansiName,
  });

  const pegawaiPemilik = user('pegawai_a', RoleName.PEGAWAI, 'Dinas PU');
  const pegawaiLain = user('pegawai_b', RoleName.PEGAWAI, 'Dinas PU');
  const adminSatuInstansi = user('admin_pu', RoleName.ADMIN, 'Dinas PU');
  const adminInstansiLain = user('admin_kes', RoleName.ADMIN, 'Dinas Kesehatan');
  const adminPembuatTugas = user('admin_creator', RoleName.ADMIN, 'Dinas Kesehatan');
  const verifSatuInstansi = user('verif_pu', RoleName.VERIFIKATOR, '  dinas pu ');
  const verifInstansiLain = user('verif_kes', RoleName.VERIFIKATOR, 'Dinas Kesehatan');
  const verifTanpaInstansi = user('verif_null', RoleName.VERIFIKATOR, null);
  const superAdmin = user('super', RoleName.SUPER_ADMIN, null);

  const task = {
    id: 'task_1',
    taskCode: 'SPPD-001',
    taskName: 'Survey Jembatan',
    assigneeId: pegawaiPemilik.id,
    creatorId: adminPembuatTugas.id,
    assignee: { instansiName: 'Dinas PU' },
  };

  const reportMeta = {
    id: 'rep_1',
    taskId: task.id,
    userId: pegawaiPemilik.id,
    reportCode: 'RPT-001',
    s3Key: 'evidence/report/2026/10/13/rep_1.pdf',
  };

  const reportLog = { id: 'log_1', metadata: reportMeta };

  const dto: UploadReportDto = {
    taskId: task.id,
    reportCode: 'RPT-001',
    title: 'Laporan Survey',
    reportSha256: 'a'.repeat(64),
    contentSnapshotJson: '{}',
  };

  const pdfFile = {
    buffer: Buffer.from('%PDF-1.4'),
    mimetype: 'application/pdf',
    originalname: 'RPT-001.pdf',
  } as Express.Multer.File;

  beforeEach(async () => {
    prisma = {
      task_SPPD: { findUnique: jest.fn().mockResolvedValue(task) },
      audit_Log: {
        findFirst: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
      },
    };
    s3Storage = {
      uploadFile: jest.fn().mockResolvedValue({
        key: 'evidence/report/2026/10/13/new.pdf',
        url: 'https://storage.tulap.id/evidence/report/2026/10/13/new.pdf',
      }),
      deleteFile: jest.fn().mockResolvedValue(undefined),
    };
    audit = { log: jest.fn().mockResolvedValue(undefined) };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LpjService,
        { provide: PrismaService, useValue: prisma },
        { provide: S3StorageService, useValue: s3Storage },
        { provide: AuditService, useValue: audit },
        { provide: NotificationsService, useValue: { notify: jest.fn() } },
      ],
    }).compile();

    service = module.get<LpjService>(LpjService);
  });

  describe('uploadReport', () => {
    it('petugas yang ditugaskan dapat mengunggah; userId diambil dari token, bukan client', async () => {
      const result = await service.uploadReport(dto, pdfFile, pegawaiPemilik);

      expect(result.userId).toBe(pegawaiPemilik.id);
      expect(s3Storage.uploadFile).toHaveBeenCalledTimes(1);
      expect(audit.log).toHaveBeenCalledWith(
        expect.objectContaining({
          actorId: pegawaiPemilik.id,
          action: 'REPORT_GENERATED',
          metadata: expect.objectContaining({ userId: pegawaiPemilik.id, taskId: task.id }),
        }),
      );
    });

    it.each([
      ['PEGAWAI lain (lintas pengguna)', pegawaiLain],
      ['ADMIN satu instansi (role escalation)', adminSatuInstansi],
      ['ADMIN pembuat tugas', adminPembuatTugas],
      ['VERIFIKATOR satu instansi', verifSatuInstansi],
      ['SUPER_ADMIN', superAdmin],
    ])('%s ditolak 403 dan tidak ada file/record yang dibuat', async (_label, actor) => {
      await expect(service.uploadReport(dto, pdfFile, actor)).rejects.toThrow(
        ForbiddenException,
      );
      expect(s3Storage.uploadFile).not.toHaveBeenCalled();
      expect(audit.log).not.toHaveBeenCalled();
    });

    it('tugas tidak ditemukan -> 404', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue(null);
      await expect(service.uploadReport(dto, pdfFile, pegawaiPemilik)).rejects.toThrow(
        NotFoundException,
      );
      expect(s3Storage.uploadFile).not.toHaveBeenCalled();
    });

    it('id laporan milik user lain -> 409, laporan lama tidak dibayangi', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue({ ...task, assigneeId: pegawaiLain.id });
      prisma.audit_Log.findFirst.mockResolvedValue(reportLog);

      await expect(
        service.uploadReport({ ...dto, id: reportMeta.id }, pdfFile, pegawaiLain),
      ).rejects.toThrow(ConflictException);
      expect(s3Storage.uploadFile).not.toHaveBeenCalled();
      expect(audit.log).not.toHaveBeenCalled();
    });

    it('retry sync oleh pemilik yang sama dengan id yang sama tetap diizinkan', async () => {
      prisma.audit_Log.findFirst.mockResolvedValue(reportLog);

      const result = await service.uploadReport(
        { ...dto, id: reportMeta.id },
        pdfFile,
        pegawaiPemilik,
      );
      expect(result.id).toBe(reportMeta.id);
    });
  });

  describe('getTaskReports', () => {
    it('petugas yang ditugaskan hanya menerima laporan tugas tsb', async () => {
      prisma.audit_Log.findMany.mockResolvedValue([
        reportLog,
        { id: 'log_2', metadata: { ...reportMeta, id: 'rep_x', taskId: 'task_lain' } },
      ]);

      const result = await service.getTaskReports(task.id, pegawaiPemilik);
      expect(result).toEqual([reportMeta]);
    });

    it.each([
      ['SUPER_ADMIN', superAdmin],
      ['ADMIN satu instansi', adminSatuInstansi],
      ['ADMIN pembuat tugas (instansi berbeda)', adminPembuatTugas],
      ['VERIFIKATOR satu instansi (beda kapital/spasi)', verifSatuInstansi],
    ])('%s diizinkan', async (_label, actor) => {
      await expect(service.getTaskReports(task.id, actor)).resolves.toEqual([]);
    });

    it.each([
      ['PEGAWAI lain (lintas pengguna)', pegawaiLain],
      ['ADMIN instansi lain', adminInstansiLain],
      ['VERIFIKATOR instansi lain', verifInstansiLain],
      ['VERIFIKATOR tanpa instansi', verifTanpaInstansi],
    ])('%s ditolak 403 tanpa membaca data laporan', async (_label, actor) => {
      await expect(service.getTaskReports(task.id, actor)).rejects.toThrow(
        ForbiddenException,
      );
      expect(prisma.audit_Log.findMany).not.toHaveBeenCalled();
    });

    it('petugas tugas tanpa instansi tidak memberi akses ke VERIFIKATOR tanpa instansi', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue({ ...task, assignee: { instansiName: null } });
      await expect(service.getTaskReports(task.id, verifTanpaInstansi)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('tugas tidak ditemukan -> 404', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue(null);
      await expect(service.getTaskReports('task_x', superAdmin)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('getReportById', () => {
    beforeEach(() => prisma.audit_Log.findFirst.mockResolvedValue(reportLog));

    it('pemilik dapat membaca; query memakai urutan deterministik', async () => {
      await expect(service.getReportById(reportMeta.id, pegawaiPemilik)).resolves.toEqual(
        reportMeta,
      );
      expect(prisma.audit_Log.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({ orderBy: { createdAt: 'asc' } }),
      );
    });

    it.each([
      ['PEGAWAI lain (lintas pengguna)', pegawaiLain],
      ['ADMIN instansi lain', adminInstansiLain],
      ['VERIFIKATOR tanpa instansi', verifTanpaInstansi],
    ])('%s ditolak 403', async (_label, actor) => {
      await expect(service.getReportById(reportMeta.id, actor)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('laporan tidak ditemukan -> 404', async () => {
      prisma.audit_Log.findFirst.mockResolvedValue(null);
      await expect(service.getReportById('rep_x', superAdmin)).rejects.toThrow(
        NotFoundException,
      );
    });

    describe('tugas induk sudah tidak ada', () => {
      beforeEach(() => prisma.task_SPPD.findUnique.mockResolvedValue(null));

      it('pengunggah dan SUPER_ADMIN masih dapat membaca', async () => {
        await expect(service.getReportById(reportMeta.id, pegawaiPemilik)).resolves.toEqual(
          reportMeta,
        );
        await expect(service.getReportById(reportMeta.id, superAdmin)).resolves.toEqual(
          reportMeta,
        );
      });

      it('ADMIN satu instansi ditolak (tidak ada dasar penilaian instansi)', async () => {
        await expect(service.getReportById(reportMeta.id, adminSatuInstansi)).rejects.toThrow(
          ForbiddenException,
        );
      });
    });
  });

  describe('deleteReport', () => {
    beforeEach(() => prisma.audit_Log.findFirst.mockResolvedValue(reportLog));

    it('pengunggah dapat menghapus: file S3 dihapus dan tercatat di audit', async () => {
      await expect(service.deleteReport(reportMeta.id, pegawaiPemilik)).resolves.toEqual(
        expect.objectContaining({ success: true }),
      );
      expect(s3Storage.deleteFile).toHaveBeenCalledWith(reportMeta.s3Key);
      expect(audit.log).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'REPORT_DELETED', actorId: pegawaiPemilik.id }),
      );
    });

    it.each([
      ['PEGAWAI lain (lintas pengguna)', pegawaiLain],
      ['ADMIN satu instansi (role escalation)', adminSatuInstansi],
      ['VERIFIKATOR satu instansi', verifSatuInstansi],
      ['SUPER_ADMIN', superAdmin],
    ])('%s ditolak 403; file S3 tidak disentuh', async (_label, actor) => {
      await expect(service.deleteReport(reportMeta.id, actor)).rejects.toThrow(
        ForbiddenException,
      );
      expect(s3Storage.deleteFile).not.toHaveBeenCalled();
      expect(audit.log).not.toHaveBeenCalled();
    });

    it('metadata tanpa userId tidak dapat dihapus siapa pun', async () => {
      prisma.audit_Log.findFirst.mockResolvedValue({
        id: 'log_legacy',
        metadata: { ...reportMeta, userId: undefined },
      });
      await expect(service.deleteReport(reportMeta.id, pegawaiPemilik)).rejects.toThrow(
        ForbiddenException,
      );
      expect(s3Storage.deleteFile).not.toHaveBeenCalled();
    });

    it('laporan tidak ditemukan -> 404', async () => {
      prisma.audit_Log.findFirst.mockResolvedValue(null);
      await expect(service.deleteReport('rep_x', pegawaiPemilik)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});
