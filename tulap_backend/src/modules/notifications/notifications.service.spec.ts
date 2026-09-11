import { Test, TestingModule } from '@nestjs/testing';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PushNotificationService } from '../../infrastructure/push/push-notification.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let prisma: any;
  let pushService: any;

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
      deviceToken: {
        findMany: jest.fn().mockResolvedValue([]),
        upsert: jest.fn().mockResolvedValue({ id: 'device_1' }),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
    };

    // Push dimatikan (isConfigured: false) di sebagian besar test - hanya
    // test khusus di bawah yang mengaktifkannya, supaya test lain (yang
    // hanya peduli baris Notification in-app) tidak perlu tahu soal FCM.
    pushService = {
      isConfigured: false,
      sendToTokens: jest.fn().mockResolvedValue([]),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        { provide: PrismaService, useValue: prisma },
        { provide: PushNotificationService, useValue: pushService },
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

  it('should not query device tokens or send push when PushNotificationService is not configured', async () => {
    await service.notify({
      userId: 'user_1',
      type: 'TASK_ASSIGNED',
      title: 'Tugas Baru',
      body: 'Anda mendapat tugas baru',
    });

    expect(prisma.deviceToken.findMany).not.toHaveBeenCalled();
    expect(pushService.sendToTokens).not.toHaveBeenCalled();
  });

  it('should send push to all of the user device tokens when configured, and prune stale ones', async () => {
    pushService.isConfigured = true;
    prisma.deviceToken.findMany.mockResolvedValue([
      { token: 'token_valid' },
      { token: 'token_stale' },
    ]);
    pushService.sendToTokens.mockResolvedValue(['token_stale']);

    await service.notify({
      userId: 'user_1',
      type: 'REVISION_NEEDED',
      title: 'Revisi diperlukan',
      body: 'Tugas Anda perlu direvisi',
      relatedTaskId: 'task_1',
    });

    expect(pushService.sendToTokens).toHaveBeenCalledWith(
      ['token_valid', 'token_stale'],
      {
        title: 'Revisi diperlukan',
        body: 'Tugas Anda perlu direvisi',
        data: {
          notificationId: 'notif_1',
          type: 'REVISION_NEEDED',
          relatedTaskId: 'task_1',
        },
      },
    );
    expect(prisma.deviceToken.deleteMany).toHaveBeenCalledWith({
      where: { token: { in: ['token_stale'] } },
    });
  });

  it('should upsert a device token scoped to the current user on register', async () => {
    await service.registerDeviceToken(
      { token: 'abc', platform: 'ANDROID' as any },
      mockUser,
    );

    expect(prisma.deviceToken.upsert).toHaveBeenCalledWith({
      where: { token: 'abc' },
      create: { token: 'abc', platform: 'ANDROID', userId: 'user_1' },
      update: { userId: 'user_1', platform: 'ANDROID' },
    });
  });

  it('should only delete a device token that belongs to the requesting user', async () => {
    await service.unregisterDeviceToken('abc', mockUser);

    expect(prisma.deviceToken.deleteMany).toHaveBeenCalledWith({
      where: { token: 'abc', userId: 'user_1' },
    });
  });
});
