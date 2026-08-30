import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let prisma: any;

  const mockUser: AuthenticatedUser = {
    id: 'user_1',
    email: 'user@tulap.id',
    fullName: 'Budi Santoso',
    role: 'PEGAWAI',
    instansiName: 'Dinas PU',
  };

  beforeEach(async () => {
    prisma = {
      notification: {
        create: jest.fn().mockResolvedValue({ id: 'notif_1' }),
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
        findUnique: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = module.get<NotificationsService>(NotificationsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should create notification with valid payload', async () => {
    await service.notify({
      userId: 'user_1',
      type: 'TASK_ASSIGNED',
      title: 'Tugas Baru',
      body: 'Anda mendapat tugas baru',
      relatedTaskId: 'task_1',
    });

    expect(prisma.notification.create).toHaveBeenCalledWith({
      data: {
        userId: 'user_1',
        type: 'TASK_ASSIGNED',
        title: 'Tugas Baru',
        body: 'Anda mendapat tugas baru',
        relatedTaskId: 'task_1',
      },
    });
  });

  it('should list notifications for user with pagination and unreadCount', async () => {
    prisma.notification.findMany.mockResolvedValue([
      { id: 'notif_1', title: 'Tugas Baru', isRead: false },
    ]);
    prisma.notification.count
      .mockResolvedValueOnce(1)
      .mockResolvedValueOnce(1);

    const result = await service.findAllForUser(mockUser, 1, 10);
    expect(result.items.length).toBe(1);
    expect(result.meta.unreadCount).toBe(1);
  });

  it('should throw NotFoundException if marking non-existent notification', async () => {
    prisma.notification.findUnique.mockResolvedValue(null);

    await expect(service.markRead('notif_999', mockUser)).rejects.toThrow(
      NotFoundException,
    );
  });

  it('should throw ForbiddenException if user marks notification owned by another user', async () => {
    prisma.notification.findUnique.mockResolvedValue({
      id: 'notif_1',
      userId: 'other_user',
    });

    await expect(service.markRead('notif_1', mockUser)).rejects.toThrow(
      ForbiddenException,
    );
  });
});
