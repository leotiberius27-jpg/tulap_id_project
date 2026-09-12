import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { TasksService } from './tasks.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { ChecklistService } from '../checklist/checklist.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { FirestoreSyncService } from '../../infrastructure/firestore/firestore-sync.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';

describe('TasksService', () => {
  let service: TasksService;
  let prisma: any;
  let checklistService: any;
  let audit: any;
  let notifications: any;
  let subscriptions: any;
  let firestoreSync: any;

  const mockAdminUser: AuthenticatedUser = {
    id: 'admin_1',
    email: 'admin@tulap.id',
    fullName: 'Admin Super',
    role: 'SUPER_ADMIN',
    instansiName: 'Dinas PU',
  };

  const mockPegawaiUser: AuthenticatedUser = {
    id: 'pegawai_1',
    email: 'budi@tulap.id',
    fullName: 'Budi Santoso',
    role: 'PEGAWAI',
    instansiName: 'Dinas PU',
  };

  beforeEach(async () => {
    prisma = {
      user: {
        findUnique: jest.fn(),
      },
      task_SPPD: {
        count: jest.fn().mockResolvedValue(0),
        create: jest.fn(),
        findUnique: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
      },
    };

    checklistService = {
      createTemplatesForTask: jest.fn().mockResolvedValue([]),
      getIncompleteMandatoryItems: jest.fn().mockResolvedValue([]),
    };

    audit = {
      log: jest.fn().mockResolvedValue(undefined),
    };

    notifications = {
      notify: jest.fn().mockResolvedValue(undefined),
    };

    subscriptions = {
      assertActivityQuotaAvailable: jest.fn().mockResolvedValue(undefined),
    };

    firestoreSync = {
      mirrorActivityReport: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TasksService,
        { provide: PrismaService, useValue: prisma },
        { provide: ChecklistService, useValue: checklistService },
        { provide: AuditService, useValue: audit },
        { provide: NotificationsService, useValue: notifications },
        { provide: SubscriptionsService, useValue: subscriptions },
        { provide: FirestoreSyncService, useValue: firestoreSync },
      ],
    }).compile();

    service = module.get<TasksService>(TasksService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should throw BadRequestException if assignee does not exist', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.create(
          {
            taskName: 'Inspeksi',
            destination: 'Jayapura',
            startDate: '2026-08-10',
            endDate: '2026-08-12',
            budgetAmount: 1500000,
            assigneeId: 'unknown_user',
          },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException if endDate is before startDate', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'pegawai_1',
        isActive: true,
        role: { name: 'PEGAWAI' },
      });

      await expect(
        service.create(
          {
            taskName: 'Inspeksi',
            destination: 'Jayapura',
            startDate: '2026-08-15',
            endDate: '2026-08-10',
            budgetAmount: 1500000,
            assigneeId: 'pegawai_1',
          },
          mockAdminUser,
        ),
      ).rejects.toThrow(BadRequestException);
    });

    it('Bagian 24 instruksi payment: menolak membuat tugas jika kuota kegiatan assignee sudah tercapai', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'pegawai_1',
        isActive: true,
        role: { name: 'PEGAWAI' },
      });
      subscriptions.assertActivityQuotaAvailable.mockRejectedValue(
        new Error('Kuota kegiatan bulan ini sudah tercapai.'),
      );

      await expect(
        service.create(
          {
            taskName: 'Inspeksi',
            destination: 'Jayapura',
            startDate: '2026-08-10',
            endDate: '2026-08-12',
            budgetAmount: 1500000,
            assigneeId: 'pegawai_1',
          },
          mockAdminUser,
        ),
      ).rejects.toThrow('Kuota kegiatan bulan ini sudah tercapai.');
      expect(prisma.task_SPPD.create).not.toHaveBeenCalled();
    });

    it('should create task and generate valid taskCode', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'pegawai_1',
        fullName: 'Budi Santoso',
        isActive: true,
        role: { name: 'PEGAWAI' },
      });

      prisma.task_SPPD.count.mockResolvedValue(0);
      prisma.task_SPPD.create.mockImplementation((args: any) =>
        Promise.resolve({
          id: 'task_123',
          ...args.data,
          status: 'DRAFT',
          assignee: { id: 'pegawai_1', fullName: 'Budi Santoso' },
          checklists: [],
        }),
      );

      const result = await service.create(
        {
          taskName: 'Inspeksi Jembatan',
          destination: 'Jayapura',
          startDate: '2026-08-10',
          endDate: '2026-08-12',
          budgetAmount: 1500000,
          assigneeId: 'pegawai_1',
        },
        mockAdminUser,
      );

      expect(result).toHaveProperty('id');
      expect(result.taskCode).toMatch(/^TL-\d{6}-\d{4}$/);
      expect(prisma.task_SPPD.create).toHaveBeenCalled();
      expect(audit.log).toHaveBeenCalled();
    });
  });

  describe('submitForVerification', () => {
    const fullTask = {
      id: 'task_1',
      taskCode: 'TL-202609-0001',
      taskName: 'Inspeksi Jembatan',
      destination: 'Jayapura',
      description: null,
      status: 'PENDING_VERIFICATION',
      assigneeId: 'pegawai_1',
      creatorId: 'admin_1',
      startDate: new Date('2026-09-10'),
      endDate: new Date('2026-09-12'),
      budgetAmount: 1500000,
      realizedAmount: 0,
      assignee: { id: 'pegawai_1', fullName: 'Budi Santoso' },
      creator: { id: 'admin_1' },
    };

    it('should mirror the report to Firestore after a successful submission', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue({
        id: 'task_1',
        assigneeId: 'pegawai_1',
        status: 'ONGOING',
      });
      prisma.task_SPPD.update.mockResolvedValue(fullTask);

      const result = await service.submitForVerification('task_1', mockPegawaiUser);

      expect(result).toEqual(fullTask);
      expect(firestoreSync.mirrorActivityReport).toHaveBeenCalledWith({
        id: 'task_1',
        taskCode: 'TL-202609-0001',
        taskName: 'Inspeksi Jembatan',
        destination: 'Jayapura',
        description: null,
        status: 'PENDING_VERIFICATION',
        assigneeId: 'pegawai_1',
        assigneeName: 'Budi Santoso',
        creatorId: 'admin_1',
        startDate: fullTask.startDate,
        endDate: fullTask.endDate,
        budgetAmount: 1500000,
        realizedAmount: 0,
      });
    });

    it('should throw and never touch Firestore when mandatory checklist items are incomplete', async () => {
      prisma.task_SPPD.findUnique.mockResolvedValue({
        id: 'task_1',
        assigneeId: 'pegawai_1',
        status: 'ONGOING',
      });
      checklistService.getIncompleteMandatoryItems.mockResolvedValue([
        { id: 'item_1', label: 'Foto lokasi' },
      ]);

      await expect(
        service.submitForVerification('task_1', mockPegawaiUser),
      ).rejects.toThrow(BadRequestException);

      expect(firestoreSync.mirrorActivityReport).not.toHaveBeenCalled();
    });
  });
});
