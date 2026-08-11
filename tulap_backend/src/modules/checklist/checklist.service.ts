import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import {
  CreateChecklistItemDto,
  CreateChecklistItemsBulkDto,
} from './dto/create-checklist-item.dto';

@Injectable()
export class ChecklistService {
  constructor(private readonly prisma: PrismaService) {}

  async findByTask(taskId: string, actor: AuthenticatedUser) {
    const task = await this._verifyTaskAccess(taskId, actor);

    return this.prisma.task_Checklist_Item.findMany({
      where: { taskId },
      orderBy: { order: 'asc' },
    });
  }

  /// Dipanggil ADMIN saat membuat penugasan - membuat seluruh item
  /// checklist sekaligus. Task HARUS masih berstatus DRAFT, sejalan
  /// dengan aturan "hanya tugas Draft yang dapat diedit" di TasksService.
  async createBulk(
    taskId: string,
    dto: CreateChecklistItemsBulkDto,
    actor: AuthenticatedUser,
  ) {
    const task = await this._findTaskOrThrow(taskId);

    if (task.status !== 'DRAFT') {
      throw new BadRequestException(
        'Checklist hanya dapat ditambahkan pada tugas berstatus Draft.',
      );
    }

    if (!dto.items || dto.items.length === 0) {
      throw new BadRequestException('Minimal satu item checklist diperlukan.');
    }

    await this.prisma.task_Checklist_Item.createMany({
      data: dto.items.map((item) => ({
        taskId,
        label: item.label,
        order: item.order,
        isMandatory: item.isMandatory ?? true,
      })),
    });

    return this.findByTask(taskId, actor);
  }

  /// Dipanggil PEGAWAI saat mencentang/membatalkan centang item
  /// checklist selagi bekerja di lapangan.
  async toggleComplete(
    taskId: string,
    itemId: string,
    isCompleted: boolean,
    actor: AuthenticatedUser,
  ) {
    const task = await this._findTaskOrThrow(taskId);

    if (actor.role === RoleName.PEGAWAI && task.assigneeId !== actor.id) {
      throw new ForbiddenException('Anda bukan petugas yang ditugaskan pada tugas ini.');
    }

    const item = await this.prisma.task_Checklist_Item.findUnique({
      where: { id: itemId },
    });

    if (!item || item.taskId !== taskId) {
      throw new NotFoundException('Item checklist tidak ditemukan.');
    }

    return this.prisma.task_Checklist_Item.update({
      where: { id: itemId },
      data: {
        isCompleted,
        completedAt: isCompleted ? new Date() : null,
      },
    });
  }

  /// Dipanggil TasksService.submitForVerification SEBELUM mengizinkan
  /// transisi status ke PENDING_VERIFICATION - inilah yang menuntaskan
  /// catatan tertunda "Validasi kelengkapan bukti wajib akan
  /// ditambahkan di sini saat modul TaskChecklist dibangun."
  ///
  /// Mengembalikan daftar label item yang BELUM lengkap (bukan hanya
  /// boolean true/false), agar pesan error ke pegawai bisa spesifik
  /// menyebutkan item mana yang kurang - sesuai prinsip UX Bagian 17:
  /// error harus jelas dan actionable, bukan generik.
  async getIncompleteMandatoryItems(taskId: string): Promise<string[]> {
    const incompleteItems = await this.prisma.task_Checklist_Item.findMany({
      where: { taskId, isMandatory: true, isCompleted: false },
      orderBy: { order: 'asc' },
    });

    return incompleteItems.map((item) => item.label);
  }

  private async _findTaskOrThrow(taskId: string) {
    const task = await this.prisma.task_SPPD.findUnique({ where: { id: taskId } });
    if (!task) {
      throw new NotFoundException('Tugas tidak ditemukan.');
    }
    return task;
  }

  private async _verifyTaskAccess(taskId: string, actor: AuthenticatedUser) {
    const task = await this._findTaskOrThrow(taskId);
    if (actor.role === RoleName.PEGAWAI && task.assigneeId !== actor.id) {
      throw new ForbiddenException('Anda tidak memiliki akses ke tugas ini.');
    }
    return task;
  }
}
