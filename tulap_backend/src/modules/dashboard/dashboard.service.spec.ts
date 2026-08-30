import { Test, TestingModule } from '@nestjs/testing';
import { DashboardService } from './dashboard.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { DashboardPeriodEnum } from './dto/dashboard-query.dto';

describe('DashboardService', () => {
  let service: DashboardService;
  let prisma: PrismaService;

  const mockUser: AuthenticatedUser = {
    id: 'user-001',
    email: 'petugas@tulap.id',
    fullName: 'Leonardo Petugas',
    role: 'PEGAWAI',
    instansiName: 'Dinas Pekerjaan Umum',
  };

  const sampleTasks = [
    {
      id: 'task-1',
      taskCode: 'TL-202608-0001',
      taskName: 'Inspeksi Jembatan Mimika',
      destination: 'Kabupaten Mimika, Papua',
      startDate: new Date('2026-08-10T08:00:00Z'),
      status: 'VERIFIED',
      assigneeId: 'user-001',
    },
    {
      id: 'task-2',
      taskCode: 'TL-202608-0002',
      taskName: 'Pemeliharaan Jalan Timika',
      destination: 'Timika, Mimika',
      startDate: new Date('2026-08-15T09:00:00Z'),
      status: 'COMPLETED',
      assigneeId: 'user-001',
    },
    {
      id: 'task-3',
      taskCode: 'TL-202608-0003',
      taskName: 'Audit Drainase Jayapura',
      destination: 'Jayapura Utara',
      startDate: new Date('2026-08-20T10:00:00Z'),
      status: 'REVISION_NEEDED',
      assigneeId: 'user-001',
    },
    {
      id: 'task-4',
      taskCode: 'TL-202608-0004',
      taskName: 'Survei Irigasi Nabire',
      destination: 'Nabire Kota',
      startDate: new Date('2026-08-25T11:00:00Z'),
      status: 'ONGOING',
      assigneeId: 'user-001',
    },
  ];

  const samplePhotos = [
    {
      id: 'photo-1',
      createdAt: new Date('2026-08-10T08:30:00Z'),
      latitude: -4.5468,
      longitude: 136.8837,
      address: 'Kabupaten Mimika, Papua Tengah',
    },
    {
      id: 'photo-2',
      createdAt: new Date('2026-08-15T09:30:00Z'),
      latitude: -4.5468,
      longitude: 136.8837,
      address: 'Timika, Mimika',
    },
    {
      id: 'photo-3',
      createdAt: new Date('2026-08-20T10:30:00Z'),
      latitude: -2.5337,
      longitude: 140.7181,
      address: 'Jayapura, Papua',
    },
  ];

  const sampleExpenses = [
    {
      id: 'exp-1',
      totalAmount: 3200000,
      category: 'TRANSPORTASI_LAIN',
      verificationStatus: 'VERIFIED',
      createdAt: new Date('2026-08-10T12:00:00Z'),
    },
    {
      id: 'exp-2',
      totalAmount: 2400000,
      category: 'PENGINAPAN',
      verificationStatus: 'VERIFIED',
      createdAt: new Date('2026-08-11T12:00:00Z'),
    },
    {
      id: 'exp-3',
      totalAmount: 1850000,
      category: 'BBM',
      verificationStatus: 'VERIFIED',
      createdAt: new Date('2026-08-12T12:00:00Z'),
    },
    {
      id: 'exp-4',
      totalAmount: 1300000,
      category: 'KONSUMSI',
      verificationStatus: 'VERIFIED',
      createdAt: new Date('2026-08-13T12:00:00Z'),
    },
    {
      id: 'exp-draft',
      totalAmount: 500000,
      category: 'LAINNYA',
      verificationStatus: 'PENDING', // Unconfirmed draft
      createdAt: new Date('2026-08-14T12:00:00Z'),
    },
  ];

  const sampleTravelMissions = [
    {
      id: 'travel-1',
      displayId: 'PD-20260828-001',
      destination: 'Jayapura',
      departureDate: new Date('2026-08-05T08:00:00Z'),
      returnDate: new Date('2026-08-08T18:00:00Z'),
      status: 'COMPLETED',
      lpjPackages: [{ id: 'lpj-1' }],
    },
    {
      id: 'travel-2',
      displayId: 'PD-20260828-002',
      destination: 'Nabire',
      departureDate: new Date('2026-08-20T08:00:00Z'),
      returnDate: new Date('2026-08-22T18:00:00Z'),
      status: 'ONGOING',
      lpjPackages: [], // Incomplete LPJ
    },
  ];

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DashboardService,
        {
          provide: PrismaService,
          useValue: {
            task_SPPD: { findMany: jest.fn().mockResolvedValue(sampleTasks) },
            geotag_Photo: { findMany: jest.fn().mockResolvedValue(samplePhotos) },
            expense_Note: { findMany: jest.fn().mockResolvedValue(sampleExpenses) },
            travel_Mission: { findMany: jest.fn().mockResolvedValue(sampleTravelMissions) },
          },
        },
      ],
    }).compile();

    service = module.get<DashboardService>(DashboardService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should calculate Activity KPI and completion rate accurately', async () => {
    const result = await service.getDashboard(
      { period: DashboardPeriodEnum.THIS_MONTH },
      mockUser,
    );

    expect(result.summary.activityTotal).toBe(4);
    expect(result.summary.activityCompleted).toBe(2); // verified + completed
    expect(result.summary.activityOngoing).toBe(2); // revision_needed + ongoing
    expect(result.summary.activityCompletionRate).toBe(50.0);
  });

  it('should calculate Evidence KPI correctly', async () => {
    const result = await service.getDashboard(
      { period: DashboardPeriodEnum.THIS_MONTH },
      mockUser,
    );

    expect(result.summary.evidenceTotal).toBe(3);
    expect(result.summary.photoCount).toBe(3);
  });

  it('should sum confirmed expenses only and exclude unconfirmed drafts', async () => {
    const result = await service.getDashboard(
      { period: DashboardPeriodEnum.THIS_MONTH },
      mockUser,
    );

    // 3.2M + 2.4M + 1.85M + 1.3M = 8,750,000 (Pending draft 500,000 excluded)
    expect(result.summary.expenseTotal).toBe(8750000);
    expect(result.expenseByCategory.length).toBe(4);
    expect(result.expenseByCategory[0].category).toBe('Transportasi');
    expect(result.expenseByCategory[0].amount).toBe(3200000);
  });

  it('should calculate Travel and LPJ completeness metrics', async () => {
    const result = await service.getDashboard(
      { period: DashboardPeriodEnum.THIS_MONTH },
      mockUser,
    );

    expect(result.summary.travelTotal).toBe(2);
    expect(result.summary.travelDays).toBe(7); // 4 + 3 (inclusive days)
    expect(result.summary.lpjComplete).toBe(1);
    expect(result.summary.lpjIncomplete).toBe(1);
  });

  it('should surface Action Required items for incomplete LPJ and unconfirmed drafts', async () => {
    const result = await service.getDashboard(
      { period: DashboardPeriodEnum.THIS_MONTH },
      mockUser,
    );

    expect(result.actionRequired.length).toBeGreaterThanOrEqual(2);
    const lpjAction = result.actionRequired.find((a) => a.type === 'lpjIncomplete');
    expect(lpjAction).toBeDefined();
    expect(lpjAction?.count).toBe(1);

    const reviewAction = result.actionRequired.find((a) => a.type === 'receiptNeedsReview');
    expect(reviewAction).toBeDefined();
    expect(reviewAction?.count).toBe(1);
  });

  it('should aggregate top locations from tasks and photos', async () => {
    const result = await service.getDashboard(
      { period: DashboardPeriodEnum.THIS_MONTH },
      mockUser,
    );

    expect(result.topLocations.length).toBeGreaterThan(0);
    expect(result.topLocations.some((l) => l.location.includes('Mimika'))).toBe(true);
  });
});
