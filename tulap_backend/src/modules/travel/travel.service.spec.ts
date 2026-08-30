import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuditService } from '../audit/audit.service';
import { TravelService } from './travel.service';

describe('TravelService', () => {
  let service: TravelService;
  let prisma: any;
  let audit: any;

  beforeEach(async () => {
    prisma = {
      travel_Mission: {
        findUnique: jest.fn(),
        create: jest.fn(),
        findMany: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      supporting_Document: {
        findUnique: jest.fn(),
        create: jest.fn(),
        findMany: jest.fn(),
        delete: jest.fn(),
      },
      lPJ_Package: {
        findUnique: jest.fn(),
        create: jest.fn(),
        findMany: jest.fn(),
      },
    };

    audit = {
      log: jest.fn().mockResolvedValue(undefined),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TravelService,
        { provide: PrismaService, useValue: prisma },
        { provide: S3StorageService, useValue: {} },
        { provide: AuditService, useValue: audit },
      ],
    }).compile();

    service = module.get<TravelService>(TravelService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create travel mission and log audit event', async () => {
    const dto = {
      id: 'travel-1',
      displayId: 'PD-20260828-0001',
      assignmentLetterNumber: 'ST/001/2026',
      assignmentLetterDate: '2026-08-28T00:00:00.000Z',
      title: 'Koordinasi Jayapura',
      purpose: 'Rapat Teknis SPPD',
      origin: 'Timika',
      destination: 'Jayapura',
      departureDate: '2026-08-28T00:00:00.000Z',
      returnDate: '2026-08-30T00:00:00.000Z',
      transportMode: 'PESAWAT',
    };

    prisma.travel_Mission.findUnique.mockResolvedValue(null);
    prisma.travel_Mission.create.mockResolvedValue({ ...dto, userId: 'user-1' });

    const result = await service.createTravelMission('user-1', dto as any);
    expect(result.id).toBe('travel-1');
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'user-1',
        action: 'TRAVEL_CREATED',
        entity: 'Travel_Mission',
        entityId: 'travel-1',
      }),
    );
  });

  it('should list travel missions for authenticated user', async () => {
    prisma.travel_Mission.findMany.mockResolvedValue([{ id: 'travel-1' }]);
    const results = await service.findAllTravelMissions('user-1');
    expect(results).toHaveLength(1);
  });
});
