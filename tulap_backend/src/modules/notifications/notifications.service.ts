import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';

/// NotificationsService
/// ----------------------------------------------------------------------
/// `notify()` adalah jalur resmi membuat notifikasi baru - dipanggil dari
/// service lain (tasks/lpj) saat peristiwa yang relevan terjadi (Bagian
/// 25 dokumen spesifikasi: Notification System). Sisanya (list/markRead)
/// dipanggil langsung dari NotificationsController untuk kebutuhan
/// mobile/web membaca & menandai notifikasi milik user yang login.
/// ----------------------------------------------------------------------
@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async notify(params: {
    userId: string;
    type: NotificationType;
    title: string;
    body: string;
    relatedTaskId?: string;
  }): Promise<void> {
    await this.prisma.notification.create({
      data: {
        userId: params.userId,
        type: params.type,
        title: params.title,
        body: params.body,
        relatedTaskId: params.relatedTaskId,
      },
    });
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
