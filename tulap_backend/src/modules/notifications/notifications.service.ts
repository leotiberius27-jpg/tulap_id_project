import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { DevicePlatform, NotificationType } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { PushNotificationService } from '../../infrastructure/push/push-notification.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';

/// NotificationsService
/// ----------------------------------------------------------------------
/// `notify()` adalah jalur resmi membuat notifikasi baru - dipanggil dari
/// service lain (tasks/lpj) saat peristiwa yang relevan terjadi (Bagian
/// 25 dokumen spesifikasi: Notification System). Sisanya (list/markRead)
/// dipanggil langsung dari NotificationsController untuk kebutuhan
/// mobile/web membaca & menandai notifikasi milik user yang login.
///
/// `notify()` JUGA mengirim push notification (FCM) ke seluruh device
/// token milik user itu, best-effort - lihat PushNotificationService.
/// Baris Notification in-app di atas SELALU tersimpan terlepas dari
/// berhasil/tidaknya/dikonfigurasi-tidaknya push itu.
/// ----------------------------------------------------------------------
@Injectable()
export class NotificationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly pushNotificationService: PushNotificationService,
  ) {}

  async notify(params: {
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    relatedTaskId?: string;
  }): Promise<void> {
    const notification = await this.prisma.notification.create({
      data: {
        userId: params.userId,
        type: params.type,
        title: params.title,
        body: params.body,
        relatedTaskId: params.relatedTaskId,
      },
    });

    await this.pushToUserDevices(params.userId, {
      title: params.title,
      body: params.body,
      data: {
        notificationId: notification.id,
        type: params.type,
        ...(params.relatedTaskId ? { relatedTaskId: params.relatedTaskId } : {}),
      },
    });
  }

  private async pushToUserDevices(
    userId: string,
    payload: { title: string; body: string; data: Record<string, string> },
  ): Promise<void> {
    if (!this.pushNotificationService.isConfigured) return;

    const deviceTokens = await this.prisma.deviceToken.findMany({
      where: { userId },
      select: { token: true },
    });
    if (deviceTokens.length === 0) return;

    const staleTokens = await this.pushNotificationService.sendToTokens(
      deviceTokens.map((d) => d.token),
      payload,
    );
    if (staleTokens.length > 0) {
      await this.prisma.deviceToken.deleteMany({
        where: { token: { in: staleTokens } },
      });
    }
  }

  /// Mendaftarkan/memperbarui token FCM perangkat milik user yang login.
  /// `token` unique lintas seluruh tabel - jika perangkat yang sama
  /// sebelumnya terdaftar ke akun lain (logout lalu login akun berbeda
  /// di HP itu), baris yang sudah ada diambil-alih ke user saat ini,
  /// BUKAN membuat baris duplikat.
  async registerDeviceToken(dto: RegisterDeviceTokenDto, actor: AuthenticatedUser) {
    await this.prisma.deviceToken.upsert({
      where: { token: dto.token },
      create: {
        token: dto.token,
        platform: dto.platform ?? DevicePlatform.ANDROID,
        userId: actor.id,
      },
      update: {
        userId: actor.id,
        platform: dto.platform ?? DevicePlatform.ANDROID,
      },
    });
    return { success: true };
  }

  /// Dipanggil saat logout - hapus HANYA jika token itu memang milik
  /// user yang meminta (mencegah user menghapus token orang lain dengan
  /// menebak nilainya).
  async unregisterDeviceToken(token: string, actor: AuthenticatedUser) {
    await this.prisma.deviceToken.deleteMany({
      where: { token, userId: actor.id },
    });
    return { success: true };
  }

  async findAllForUser(actor: AuthenticatedUser, page: number, pageSize: number) {
    const where = { userId: actor.id };

    const [items, total, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where,
        skip: (page - 1) * pageSize,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.notification.count({ where }),
      this.prisma.notification.count({ where: { ...where, isRead: false } }),
    ]);

    return {
      items,
      meta: { page, pageSize, total, totalPages: Math.ceil(total / pageSize), unreadCount },
    };
  }

  async markRead(id: string, actor: AuthenticatedUser) {
    const notification = await this.prisma.notification.findUnique({ where: { id } });
    if (!notification) {
      throw new NotFoundException('Notifikasi tidak ditemukan.');
    }
    if (notification.userId !== actor.id) {
      throw new ForbiddenException('Anda tidak memiliki akses ke notifikasi ini.');
    }
    return this.prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }

  async markAllRead(actor: AuthenticatedUser) {
    await this.prisma.notification.updateMany({
      where: { userId: actor.id, isRead: false },
      data: { isRead: true },
    });
    return { success: true };
  }
}
