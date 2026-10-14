import { Test, TestingModule } from '@nestjs/testing';
import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { RoleName, TaskStatus } from '@prisma/client';
import { EvidenceService } from './evidence.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuditService } from '../audit/audit.service';
import { FirestoreSyncService } from '../../infrastructure/firestore/firestore-sync.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';

/// Regression test P0-03: sebelum perbaikan, pengunggah dapat
/// menghapus permanen foto/nota KAPAN PUN (termasuk setelah tugas
/// VERIFIED/COMPLETED), dan ADMIN/VERIFIKATOR/SUPER_ADMIN dapat
/// menghapus bukti milik siapa pun dari instansi mana pun.
describe('EvidenceService - kunci penghapusan bukti', () => {
  let service: EvidenceService;
  let prisma: any;
  let audit: any;

  const user = (id: string, role: RoleName): AuthenticatedUser => ({
    id,
    email: `${id}@tulap.id`,
    fullName: id,
    role,
    instansiName: 'Dinas PU',
  });

  const pengunggah = user('pegawai_a', RoleName.PEGAWAI);
  const assigneeBukanPengunggah = user('pegawai_assignee', RoleName.PEGAWAI);
  const pegawaiLain = user('pegawai_b', RoleName.PEGAWAI);
  const admin = user('admin', RoleName.ADMIN);
  const verifikator = user('verif', RoleName.VERIFIKATOR);
  const superAdmin = user('super', RoleName.SUPER_ADMIN);

  const editable = [TaskStatus.DRAFT, TaskStatus.ONGOING, TaskStatus.REVISION_NEEDED];
  const locked = [
    TaskStatus.PENDING_VERIFICATION,
    TaskStatus.VERIFIED,
    TaskStatus.REJECTED,
    TaskStatus.COMPLETED,
  ];

  const photo = (assigneeId = pengunggah.id) => ({
    id: 'photo_1',
    taskId: 'task_1',
    uploaderId: pengunggah.id,
    caption: 'Kondisi awal',
    task: { id: 'task_1', taskCode: 'SPPD-1', taskName: 'Survey', destination: 'X', assigneeId },
    uploader: { id: pengunggah.id, fullName: 'A', instansiName: 'Dinas PU', unitKerja: null },
  });

  const receipt = (status: TaskStatus) => ({
    id: 'note_1',
    taskId: 'task_1',
    ownerId: pengunggah.id,
    vendorName: 'SPBU 34.123',
    totalAmount: 150000,
    task: { id: 'task_1', status, assigneeId: pengunggah.id },
  });

  beforeEach(async () => {
    prisma = {
      task_SPPD: { findUnique: jest.fn() },
      geotag_Photo: {
        findUnique: jest.fn().mockResolvedValue(photo()),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        delete: jest.fn(),
      },
      expense_Note: {
        findUnique: jest.fn(),
        deleteMany: jest.fn().mockResolvedValue({ count: 1 }),
        delete: jest.fn(),
      },
    };
    audit = { log: jest.fn().mockResolvedValue(undefined) };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        EvidenceService,
        { provide: PrismaService, useValue: prisma },
        { provide: S3StorageService, useValue: { uploadFile: jest.fn() } },
        { provide: AuditService, useValue: audit },
        { provide: FirestoreSyncService, useValue: { mirrorAssetDocument: jest.fn() } },
      ],
    }).compile();

    service = module.get<EvidenceService>(EvidenceService);
  });

  const expectNothingDeleted = () => {
    expect(prisma.geotag_Photo.deleteMany).not.toHaveBeenCalled();
    expect(prisma.geotag_Photo.delete).not.toHaveBeenCalled();
    expect(prisma.expense_Note.deleteMany).not.toHaveBeenCalled();
    expect(prisma.expense_Note.delete).not.toHaveBeenCalled();
    expect(audit.log).not.toHaveBeenCalled();
  };

  describe('deleteEvidencePhoto', () => {
    it.each(editable)('tugas %s: pengunggah dapat menghapus; syarat ikut di query DELETE', async (status) => {
      prisma.task_SPPD.findUnique.mockResolvedValue({ status });

      await expect(service.deleteEvidencePhoto('photo_1', pengunggah)).resolves.toEqual(
        expect.objectContaining({ success: true }),
      );
      expect(prisma.geotag_Photo.deleteMany).toHaveBeenCalledWith({
        where: {
          id: 'photo_1',
          uploaderId: pengunggah.id,
          task: { is: { status: { in: editable } } },
        },
      });
      expect(audit.log).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'EVIDENCE_DELETED', actorId: pengunggah.id }),
      );
    });

    it.each(locked)('tugas %s: bukti terkunci -> 409, tidak ada yang terhapus', async (status) => {
      prisma.task_SPPD.findUnique.mockResolvedValue({ status });

      await expect(service.deleteEvidencePhoto('photo_1', pengunggah)).rejects.toThrow(
        ConflictException,
      );
      expectNothingDeleted();
    });

    it.each([
      ['ADMIN', admin],
      ['VERIFIKATOR', verifikator],
      ['SUPER_ADMIN', superAdmin],
    ])('%s tidak dapat menghapus bukti milik pegawai (tugas masih berjalan)', async (_l, actor) => {
      prisma.task_SPPD.findUnique.mockResolvedValue({ status: TaskStatus.ONGOING });

      await expect(service.deleteEvidencePhoto('photo_1', actor)).rejects.toThrow(
        ForbiddenException,
      );
      expectNothingDeleted();
    });

    it('assignee tugas yang BUKAN pengunggah boleh melihat tetapi tidak boleh menghapus', async () => {
      prisma.geotag_Photo.findUnique.mockResolvedValue(photo(assigneeBukanPengunggah.id));
      prisma.task_SPPD.findUnique.mockResolvedValue({ status: TaskStatus.ONGOING });

      await expect(service.getEvidencePhoto('photo_1', assigneeBukanPengunggah)).resolves.toBeDefined();
      await expect(
        service.deleteEvidencePhoto('photo_1', assigneeBukanPengunggah),
      ).rejects.toThrow(ForbiddenException);
      expectNothingDeleted();
    });

    it('PEGAWAI lain -> 403', async () => {
      await expect(service.deleteEvidencePhoto('photo_1', pegawaiLain)).rejects.toThrow(
        ForbiddenException,
      );
      expectNothingDeleted();
    });

    it('bukti tidak ada -> 404', async () => {
      prisma.geotag_Photo.findUnique.mockResolvedValue(null);
      await expect(service.deleteEvidencePhoto('photo_x', pengunggah)).rejects.toThrow(
        NotFoundException,
      );
      expectNothingDeleted();
    });

    it('race: tugas dikirim tepat setelah pengecekan -> DELETE atomik tidak menghapus apa pun -> 409', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue({ status: TaskStatus.ONGOING });
      prisma.geotag_Photo.deleteMany.mockResolvedValue({ count: 0 });

      await expect(service.deleteEvidencePhoto('photo_1', pengunggah)).rejects.toThrow(
        ConflictException,
      );
      expect(audit.log).not.toHaveBeenCalled();
    });
  });

  describe('deleteEvidenceReceipt', () => {
    it.each(editable)('tugas %s: pemilik dapat menghapus; syarat ikut di query DELETE', async (status) => {
      prisma.expense_Note.findUnique.mockResolvedValue(receipt(status));

      await expect(service.deleteEvidenceReceipt('note_1', pengunggah)).resolves.toEqual(
        expect.objectContaining({ success: true }),
      );
      expect(prisma.expense_Note.deleteMany).toHaveBeenCalledWith({
        where: {
          id: 'note_1',
          ownerId: pengunggah.id,
          task: { is: { status: { in: editable } } },
        },
      });
      expect(audit.log).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'EVIDENCE_RECEIPT_DELETED', actorId: pengunggah.id }),
      );
    });

    it.each(locked)('tugas %s: nota terkunci -> 409, tidak ada yang terhapus', async (status) => {
      prisma.expense_Note.findUnique.mockResolvedValue(receipt(status));

      await expect(service.deleteEvidenceReceipt('note_1', pengunggah)).rejects.toThrow(
        ConflictException,
      );
      expectNothingDeleted();
    });

    it.each([
      ['PEGAWAI lain', pegawaiLain],
      ['ADMIN', admin],
      ['VERIFIKATOR', verifikator],
      ['SUPER_ADMIN', superAdmin],
    ])('%s tidak dapat menghapus nota milik pegawai', async (_l, actor) => {
      prisma.expense_Note.findUnique.mockResolvedValue(receipt(TaskStatus.ONGOING));

      await expect(service.deleteEvidenceReceipt('note_1', actor)).rejects.toThrow(
        ForbiddenException,
      );
      expectNothingDeleted();
    });

    it('nota tidak ada -> 404', async () => {
      prisma.expense_Note.findUnique.mockResolvedValue(null);
      await expect(service.deleteEvidenceReceipt('note_x', pengunggah)).rejects.toThrow(
        NotFoundException,
      );
      expectNothingDeleted();
    });

    it('race: DELETE atomik tidak menghapus apa pun -> 409 tanpa audit', async () => {
      prisma.expense_Note.findUnique.mockResolvedValue(receipt(TaskStatus.ONGOING));
      prisma.expense_Note.deleteMany.mockResolvedValue({ count: 0 });

      await expect(service.deleteEvidenceReceipt('note_1', pengunggah)).rejects.toThrow(
        ConflictException,
      );
      expect(audit.log).not.toHaveBeenCalled();
    });
  });
});
