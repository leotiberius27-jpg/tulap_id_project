import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { RoleName } from '@prisma/client';
import { AssistantService } from './assistant.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { SearchService } from '../search/search.service';
import { AssistantLanguageModel } from './services/assistant-language-model.interface';
import { DefaultAssistantLanguageModelService } from './services/default-assistant-language-model.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { AssistantIntentEnum } from './dto/assistant-response.dto';

/// Regression test N-10: IDOR baca di asisten "Tanya Tulap". Sebelum
/// perbaikan, PEGAWAI yang mengirim `contextEntityId` milik tugas orang
/// lain menerima nama tugas, kode, tujuan, jumlah foto & nota tugas tsb
/// (handleReportAssistance), atau nama tugas + aksi "Tandai Selesai"
/// untuk tugas itu (handleWriteAction).
describe('AssistantService - akses contextEntityId (N-10)', () => {
  let service: AssistantService;
  let prisma: any;

  const user = (id: string, role: RoleName): AuthenticatedUser => ({
    id, email: `${id}@tulap.id`, fullName: id, role, instansiName: 'Dinas PU',
  });
  const pemilik = user('pegawai_a', RoleName.PEGAWAI);
  const penyerang = user('pegawai_b', RoleName.PEGAWAI);
  const pembuat = user('admin_creator', RoleName.PEGAWAI);
  const verifikator = user('verif', RoleName.VERIFIKATOR);

  const tugasRahasia = {
    id: 'task-rahasia',
    taskCode: 'SPPD-RAHASIA-01',
    taskName: 'Audit Rahasia Gudang',
    destination: 'Gudang Rahasia',
    startDate: new Date('2026-10-01'),
    assigneeId: pemilik.id,
    creatorId: pembuat.id,
    geotagPhotos: [{ id: 'p1', caption: 'Lokasi rahasia', address: 'Jl. Rahasia 1' }],
    expenseNotes: [{ id: 'n1', vendorName: 'Vendor Rahasia', totalAmount: 999000 }],
  };

  const tugasMilikPenyerang = {
    ...tugasRahasia,
    id: 'task-b',
    taskCode: 'SPPD-B-01',
    taskName: 'Kegiatan Milik B',
    destination: 'Kota B',
    assigneeId: penyerang.id,
    creatorId: penyerang.id,
    geotagPhotos: [],
    expenseNotes: [],
  };

  beforeEach(async () => {
    prisma = {
      task_SPPD: {
        findUnique: jest.fn().mockResolvedValue(tugasRahasia),
        findFirst: jest.fn(),
        findMany: jest.fn(),
        count: jest.fn().mockResolvedValue(0),
      },
      travel_Mission: { findFirst: jest.fn(), findMany: jest.fn(), count: jest.fn() },
      expense_Note: { findMany: jest.fn(), count: jest.fn() },
      geotag_Photo: { count: jest.fn() },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AssistantService,
        { provide: PrismaService, useValue: prisma },
        { provide: SearchService, useValue: { search: jest.fn() } },
        { provide: ConfigService, useValue: { get: jest.fn().mockReturnValue(null) } },
        DefaultAssistantLanguageModelService,
        { provide: AssistantLanguageModel, useClass: DefaultAssistantLanguageModelService },
      ],
    }).compile();

    service = module.get(AssistantService);
  });

  const leaks = (response: unknown) => /RAHASIA|Rahasia|task-rahasia/.test(JSON.stringify(response));

  describe('draft laporan (handleReportAssistance)', () => {
    it('PEGAWAI lain dengan id tugas orang lain: tidak ada data tugas tsb yang bocor', async () => {
      prisma.task_SPPD.findFirst.mockResolvedValue(tugasMilikPenyerang);

      const response = await service.processQuery(
        { query: 'buat laporan', contextEntityId: 'task-rahasia' },
        penyerang,
      );

      expect(leaks(response)).toBe(false);
      // Jatuh ke tugas terbaru milik penyerang sendiri, dengan scope miliknya.
      expect(response.sources[0]?.id).toBe('task-b');
      expect(prisma.task_SPPD.findFirst).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { OR: [{ assigneeId: penyerang.id }, { creatorId: penyerang.id }] },
        }),
      );
    });

    it('respons untuk id milik orang lain identik dengan id yang tidak ada (tanpa oracle keberadaan)', async () => {
      prisma.task_SPPD.findFirst.mockResolvedValue(tugasMilikPenyerang);
      const forbidden = await service.processQuery(
        { query: 'buat laporan', contextEntityId: 'task-rahasia' },
        penyerang,
      );

      prisma.task_SPPD.findUnique.mockResolvedValue(null);
      const missing = await service.processQuery(
        { query: 'buat laporan', contextEntityId: 'tidak-ada' },
        penyerang,
      );

      expect(forbidden).toEqual(missing);
    });

    it.each([
      ['petugas yang ditugaskan', pemilik],
      ['pembuat tugas', pembuat],
      ['VERIFIKATOR (privileged, perilaku existing)', verifikator],
    ])('%s tetap mendapat draft laporan tugas tsb', async (_l, actor) => {
      const response = await service.processQuery(
        { query: 'buat laporan', contextEntityId: 'task-rahasia' },
        actor,
      );

      expect(response.intent).toBe(AssistantIntentEnum.REPORT_ASSISTANCE);
      expect(response.sources[0]?.id).toBe('task-rahasia');
      expect(response.message).toContain('Audit Rahasia Gudang');
      expect(prisma.task_SPPD.findFirst).not.toHaveBeenCalled();
    });
  });

  describe('tandai selesai (handleWriteAction)', () => {
    it('PEGAWAI lain: nama tugas tidak bocor dan tidak ada aksi untuk tugas tsb', async () => {
      const response = await service.processQuery(
        { query: 'selesaikan kegiatan ini', contextEntityId: 'task-rahasia' },
        penyerang,
      );

      expect(response.intent).toBe(AssistantIntentEnum.WRITE_ACTION);
      expect(leaks(response)).toBe(false);
      expect(response.sources).toEqual([]);
      expect(response.confirmationAction?.entityId).toBeUndefined();
      expect(response.suggestedActions?.[0]?.entityId).toBeUndefined();
    });

    it.each([
      ['petugas yang ditugaskan', pemilik],
      ['pembuat tugas', pembuat],
      ['VERIFIKATOR (privileged, perilaku existing)', verifikator],
    ])('%s mendapat konfirmasi untuk tugas tsb', async (_l, actor) => {
      const response = await service.processQuery(
        { query: 'selesaikan kegiatan ini', contextEntityId: 'task-rahasia' },
        actor,
      );

      expect(response.message).toContain('Audit Rahasia Gudang');
      expect(response.confirmationAction?.entityId).toBe('task-rahasia');
      expect(response.requiresConfirmation).toBe(true);
    });
  });
});
