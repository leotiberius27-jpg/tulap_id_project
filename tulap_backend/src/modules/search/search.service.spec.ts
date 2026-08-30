import { Test, TestingModule } from '@nestjs/testing';
import { SearchService } from './search.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { SearchEntityTypeEnum, SearchSortEnum } from './dto/search-query.dto';

describe('SearchService', () => {
  let service: SearchService;
  let prisma: PrismaService;

  const mockUser: AuthenticatedUser = {
    id: 'user_123',
    email: 'pegawai@tulap.id',
    fullName: 'Ahmad Yani',
    role: 'PEGAWAI',
    instansiName: 'Dinas PUPR',
  };

  const mockTasks = [
    {
      id: 'task_1',
      taskCode: 'ACT-20260828-001',
      taskName: 'Monitoring Kendaraan Dinas',
      destination: 'Mimika Baru, Kabupaten Mimika',
      description: 'Pemeriksaan aset kendaraan dinas operasional',
      startDate: new Date('2026-08-26T08:00:00Z'),
      endDate: new Date('2026-08-28T17:00:00Z'),
      budgetAmount: 5000000,
      status: 'COMPLETED',
      assigneeId: 'user_123',
      creatorId: 'admin_1',
      travelMissionId: 'travel_1',
      geotagPhotos: [{ id: 'p1' }, { id: 'p2' }],
      expenseNotes: [{ id: 'e1' }],
    },
  ];

  const mockTravelMissions = [
    {
      id: 'travel_1',
      displayId: 'PD-20260828-1001',
      userId: 'user_123',
      assignmentLetterNumber: 'ST.012/SETDA/VIII/2026',
      title: 'Perjalanan Dinas Jayapura',
      purpose: 'Koordinasi teknis ke provinsi Papua',
      origin: 'Timika',
      destination: 'Jayapura',
      departureDate: new Date('2026-08-20T08:00:00Z'),
      returnDate: new Date('2026-08-23T18:00:00Z'),
      transportMode: 'PESAWAT',
      status: 'LPJ_READY',
      tasks: [{ id: 'task_1' }],
      supportingDocuments: [{ id: 'doc_1' }],
      lpjPackages: [{ id: 'lpj_1' }],
    },
  ];

  const mockPhotos = [
    {
      id: 'photo_1',
      taskId: 'task_1',
      uploaderId: 'user_123',
      photoUrl: 'https://storage.tulap.id/photos/p1.jpg',
      latitude: -4.5468,
      longitude: 136.8837,
      address: 'Jalan Cenderawasih, Timika, Kabupaten Mimika',
      serverTimestamp: new Date('2026-08-26T09:42:00Z'),
      integrityHash: 'sha256_mock_hash',
      caption: 'Dokumentasi Kendaraan Hilux PA 1234 XX',
      task: { id: 'task_1', taskName: 'Monitoring Kendaraan Dinas', taskCode: 'ACT-20260828-001' },
    },
  ];

  const mockExpenses = [
    {
      id: 'exp_1',
      taskId: 'task_1',
      ownerId: 'user_123',
      scanUrl: 'https://storage.tulap.id/receipts/r1.jpg',
      vendorName: 'SPBU Pertamina Timika',
      transactionDate: new Date('2026-08-26T10:15:00Z'),
      totalAmount: 450000,
      category: 'BBM',
      ocrRawText: 'PERTAMINA DEX 450000 NO 123456 TIMIKA',
      ocrConfidence: 96.5,
      verificationStatus: 'VERIFIED',
      task: { id: 'task_1', taskName: 'Monitoring Kendaraan Dinas', taskCode: 'ACT-20260828-001' },
    },
  ];

  const mockDocs = [
    {
      id: 'doc_1',
      travelMissionId: 'travel_1',
      documentType: 'ASSIGNMENT_LETTER',
      title: 'Surat Tugas Resmi ST.012',
      documentUrl: 'https://storage.tulap.id/docs/st.pdf',
      sha256: 'doc_sha_256',
      createdAt: new Date('2026-08-19T10:00:00Z'),
      travelMission: { id: 'travel_1', title: 'Perjalanan Dinas Jayapura', displayId: 'PD-20260828-1001' },
    },
  ];

  const mockLpjs = [
    {
      id: 'lpj_1',
      travelMissionId: 'travel_1',
      packageCode: 'LPJ-20260828-9999',
      versionNumber: 1,
      title: 'Paket LPJ Resmi Perjalanan Dinas Jayapura',
      pdfUrl: 'https://storage.tulap.id/lpj/lpj1.pdf',
      packageSha256: 'lpj_sha_256',
      completenessScore: 100,
      totalActualExpense: 3450000,
      createdAt: new Date('2026-08-24T14:00:00Z'),
      travelMission: { id: 'travel_1', title: 'Perjalanan Dinas Jayapura', displayId: 'PD-20260828-1001' },
    },
  ];

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SearchService,
        {
          provide: PrismaService,
          useValue: {
            task_SPPD: { findMany: jest.fn().mockResolvedValue(mockTasks) },
            travel_Mission: { findMany: jest.fn().mockResolvedValue(mockTravelMissions) },
            geotag_Photo: { findMany: jest.fn().mockResolvedValue(mockPhotos) },
            expense_Note: { findMany: jest.fn().mockResolvedValue(mockExpenses) },
            supporting_Document: { findMany: jest.fn().mockResolvedValue(mockDocs) },
            lPJ_Package: { findMany: jest.fn().mockResolvedValue(mockLpjs) },
          },
        },
      ],
    }).compile();

    service = module.get<SearchService>(SearchService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should find activity by title (case-insensitive)', async () => {
    const res = await service.search({ q: 'monitoring kendaraan' }, mockUser);
    expect(res.items.length).toBeGreaterThan(0);
    const activity = res.items.find((i) => i.entityType === SearchEntityTypeEnum.ACTIVITY);
    expect(activity).toBeDefined();
    expect(activity?.title).toBe('Monitoring Kendaraan Dinas');
  });

  it('should find receipt by vendor and formatted amount Rp450.000', async () => {
    const res = await service.search({ q: 'Pertamina' }, mockUser);
    const receipt = res.items.find((i) => i.entityType === SearchEntityTypeEnum.RECEIPT);
    expect(receipt).toBeDefined();
    expect(receipt?.title).toBe('SPBU Pertamina Timika');

    const amountRes = await service.search({ q: 'Rp450.000' }, mockUser);
    const amountReceipt = amountRes.items.find((i) => i.entityType === SearchEntityTypeEnum.RECEIPT);
    expect(amountReceipt).toBeDefined();
  });

  it('should find travel mission by exact displayId and destination', async () => {
    const res = await service.search({ q: 'Jayapura' }, mockUser);
    const travel = res.items.find((i) => i.entityType === SearchEntityTypeEnum.TRAVEL);
    expect(travel).toBeDefined();
    expect(travel?.title).toBe('Perjalanan Dinas Jayapura');
  });

  it('should prioritize exact ID search with maximum relevance score', async () => {
    const res = await service.search({ q: 'LPJ-20260828-9999' }, mockUser);
    expect(res.items.length).toBeGreaterThan(0);
    const top = res.items[0];
    expect(top.entityType).toBe(SearchEntityTypeEnum.LPJ);
    expect(top.relevanceScore).toBe(100);
  });

  it('should filter by specific entityTypes', async () => {
    const res = await service.search(
      { q: 'Timika', entityTypes: [SearchEntityTypeEnum.EVIDENCE] },
      mockUser,
    );
    expect(res.items.every((i) => i.entityType === SearchEntityTypeEnum.EVIDENCE)).toBe(true);
  });
});
