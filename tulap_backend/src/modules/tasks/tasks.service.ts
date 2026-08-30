import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RoleName, TaskStatus } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { ChecklistService } from '../checklist/checklist.service';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { QueryTasksDto } from './dto/query-tasks.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { RevisionNoteDto } from './dto/revision-note.dto';

/// Peta transisi status yang SAH - state machine sederhana untuk
/// mencegah lompatan status yang tidak masuk akal (mis. DRAFT langsung
/// ke VERIFIED tanpa melalui submit & review). Selaras dengan alur
/// "Terima Tugas -> ... -> Verifikasi -> Revisi -> Disetujui" di
/// dokumen requirement awal.
const notificationDateFormatter = new Intl.DateTimeFormat('id-ID', {
  day: '2-digit',
  month: 'long',
  year: 'numeric',
});

const ALLOWED_TRANSITIONS: Record<TaskStatus, TaskStatus[]> = {
  DRAFT: ['ONGOING'],
  ONGOING: ['PENDING_VERIFICATION'],
  PENDING_VERIFICATION: ['VERIFIED', 'REVISION_NEEDED', 'REJECTED'],
  REVISION_NEEDED: ['PENDING_VERIFICATION'],
  VERIFIED: ['COMPLETED'],
  REJECTED: [],
  COMPLETED: [],
};

@Injectable()
export class TasksService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly checklistService: ChecklistService,
    private readonly audit: AuditService,
    private readonly notifications: NotificationsService,
  ) {}

  /// Membuat tugas baru. `taskCode` dibuat otomatis dengan format
  /// TL-<tahun><bulan>-<sequence 4 digit> agar mudah dibaca manusia
  /// namun tetap terurut & unik per bulan.
  async create(dto: CreateTaskDto, creator: AuthenticatedUser) {
    const assignee = await this.prisma.user.findUnique({
      where: { id: dto.assigneeId },
      include: { role: true },
    });

    if (!assignee || !assignee.isActive) {
      throw new BadRequestException(
        'Petugas yang dipilih tidak ditemukan atau tidak aktif.',
      );
    }

    if (new Date(dto.endDate) < new Date(dto.startDate)) {
      throw new BadRequestException(
        'Tanggal selesai tidak boleh sebelum tanggal mulai.',
      );
    }

    const taskCode = await this._generateTaskCode();

    const task = await this.prisma.task_SPPD.create({
      data: {
        taskCode,
        taskName: dto.taskName,
        destination: dto.destination,
        description: dto.description,
        startDate: new Date(dto.startDate),
        endDate: new Date(dto.endDate),
        budgetAmount: dto.budgetAmount,
        assigneeId: dto.assigneeId,
        creatorId: creator.id,
        status: 'DRAFT',
      },
      include: this._defaultInclude(),
    });

    await this.audit.log({
      actorId: creator.id,
      action: 'TASK_CREATED',
      entity: 'Task_SPPD',
      entityId: task.id,
      metadata: { taskCode: task.taskCode, assigneeId: task.assigneeId },
    });

    await this.notifications.notify({
      userId: task.assigneeId,
      type: 'TASK_ASSIGNED',
      title: 'Tugas baru ditugaskan',
      body: `Tugas baru: ${task.taskName} — ${notificationDateFormatter.format(task.startDate)}`,
      relatedTaskId: task.id,
    });

    return task;
  }

  async findAll(query: QueryTasksDto, actor: AuthenticatedUser) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 20;

    const where: any = {};

    // PEGAWAI hanya boleh melihat tugas miliknya sendiri - bukan
    // dibatasi lewat @Roles() (karena PEGAWAI memang boleh akses
    // endpoint ini), melainkan lewat filter data di sini.
    if (actor.role === RoleName.PEGAWAI) {
      where.assigneeId = actor.id;
    } else if (query.assigneeId) {
      where.assigneeId = query.assigneeId;
    }

    if (query.status) {
      where.status = query.status;
    }

    if (query.search) {
      const s = query.search.trim();
      where.OR = [
        { taskName: { contains: s, mode: 'insensitive' } },
        { taskCode: { contains: s, mode: 'insensitive' } },
        { destination: { contains: s, mode: 'insensitive' } },
        { description: { contains: s, mode: 'insensitive' } },
      ];
    }

    if (query.location) {
      where.destination = { contains: query.location.trim(), mode: 'insensitive' };
    }

    if (query.startDate || query.endDate) {
      where.startDate = {};
      if (query.startDate) {
        where.startDate.gte = new Date(query.startDate);
      }
      if (query.endDate) {
        where.startDate.lte = new Date(query.endDate);
      }
    } else if (query.year) {
      const startOfYear = new Date(query.year, 0, 1);
      const endOfYear = new Date(query.year + 1, 0, 1);
      where.startDate = {
        gte: startOfYear,
        lt: endOfYear,
      };
    }

    const [items, total] = await Promise.all([
      this.prisma.task_SPPD.findMany({
        where,
        skip: (page - 1) * pageSize,
        take: pageSize,
        orderBy: { startDate: 'desc' },
        include: this._defaultInclude(),
      }),
      this.prisma.task_SPPD.count({ where }),
    ]);

    return {
      items,
      meta: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) },
    };
  }

  async findOne(id: string, actor: AuthenticatedUser) {
    const task = await this.prisma.task_SPPD.findUnique({
      where: { id },
      include: this._defaultInclude(),
    });

    if (!task) {
      throw new NotFoundException('Tugas tidak ditemukan.');
    }

    if (actor.role === RoleName.PEGAWAI && task.assigneeId !== actor.id) {
      throw new ForbiddenException('Anda tidak memiliki akses ke tugas ini.');
    }

    return task;
  }

  /// GET /tasks/:id/evidence - dipakai Verification Workspace Web
  /// Dashboard (Bagian 15) untuk menampilkan foto & nota sebelum
  /// Verifikator memutuskan approve/revision/reject. Sebelum endpoint
  /// ini ada, satu-satunya kode yang membaca relasi geotagPhotos/
  /// expenseNotes adalah LpjService (generate PDF) - tidak ada jalan
  /// bagi dashboard untuk menampilkannya ke Verifikator sebelum LPJ
  /// dibuat. Aturan akses SAMA seperti findOne (PEGAWAI hanya boleh
  /// lihat tugas miliknya sendiri).
  async getEvidence(id: string, actor: AuthenticatedUser) {
    const task = await this.prisma.task_SPPD.findUnique({
      where: { id },
      select: { assigneeId: true },
    });

    if (!task) {
      throw new NotFoundException('Tugas tidak ditemukan.');
    }

    if (actor.role === RoleName.PEGAWAI && task.assigneeId !== actor.id) {
      throw new ForbiddenException('Anda tidak memiliki akses ke tugas ini.');
    }

    const [photos, expenseNotes] = await Promise.all([
      this.prisma.geotag_Photo.findMany({
        where: { taskId: id },
        orderBy: { serverTimestamp: 'asc' },
      }),
      this.prisma.expense_Note.findMany({
        where: { taskId: id },
        orderBy: { transactionDate: 'asc' },
      }),
    ]);

    return { photos, expenseNotes };
  }

  async update(id: string, dto: UpdateTaskDto) {
    const task = await this._findOrThrow(id);

    // Tugas yang sudah lewat dari status DRAFT tidak boleh diedit data
    // intinya (nama, lokasi, anggaran) - hanya boleh diedit selagi
    // masih draft, untuk menjaga konsistensi data setelah pegawai
    // mulai bekerja berdasarkan informasi tsb.
    if (task.status !== 'DRAFT') {
      throw new BadRequestException(
        'Tugas yang sudah berjalan tidak dapat diubah datanya. Hanya tugas berstatus Draft yang dapat diedit.',
      );
    }

    if (dto.assigneeId) {
      const assignee = await this.prisma.user.findUnique({
        where: { id: dto.assigneeId },
      });
      if (!assignee || !assignee.isActive) {
        throw new BadRequestException('Petugas yang dipilih tidak valid.');
      }
    }

    return this.prisma.task_SPPD.update({
      where: { id },
      data: {
        taskName: dto.taskName,
        destination: dto.destination,
        description: dto.description,
        startDate: dto.startDate ? new Date(dto.startDate) : undefined,
        endDate: dto.endDate ? new Date(dto.endDate) : undefined,
        budgetAmount: dto.budgetAmount,
        assigneeId: dto.assigneeId,
      },
      include: this._defaultInclude(),
    });
  }

  /// transitionStatus
  /// ----------------------------------------------------------------------
  /// SATU-SATUNYA jalur resmi mengubah status tugas - menegakkan state
  /// machine ALLOWED_TRANSITIONS di atas. Dipanggil oleh method publik
  /// yang lebih spesifik (startTask, submitForVerification, dst) agar
  /// caller di controller tidak bisa sembarangan set status apa pun.
  /// ----------------------------------------------------------------------
  private async transitionStatus(
    id: string,
    newStatus: TaskStatus,
    actor: AuthenticatedUser,
  ) {
    const task = await this._findOrThrow(id);

    const allowedNextStatuses = ALLOWED_TRANSITIONS[task.status];
    if (!allowedNextStatuses.includes(newStatus)) {
      throw new BadRequestException(
        `Tugas berstatus '${task.status}' tidak dapat diubah langsung menjadi '${newStatus}'.`,
      );
    }

    return this.prisma.task_SPPD.update({
      where: { id },
      data: { status: newStatus },
      include: this._defaultInclude(),
    });
  }

  /// Dipanggil PEGAWAI saat mulai bekerja di lapangan ("Lanjutkan
  /// Tugas" pertama kali ditekan setelah tiba di lokasi).
  async startTask(id: string, actor: AuthenticatedUser) {
    const task = await this._findOrThrow(id);
    if (task.assigneeId !== actor.id) {
      throw new ForbiddenException('Anda bukan petugas yang ditugaskan pada tugas ini.');
    }
    return this.transitionStatus(id, 'ONGOING', actor);
  }

  /// Dipanggil PEGAWAI saat "Kirim Tugas" ditekan - menandai tugas
  /// siap direview Verifikator. SEBELUM transisi status diizinkan,
  /// SELURUH item checklist yang bersifat wajib (isMandatory=true)
  /// harus sudah dicentang - ini menuntaskan validasi kelengkapan
  /// bukti yang sebelumnya baru berupa catatan rencana.
  async submitForVerification(id: string, actor: AuthenticatedUser) {
    const task = await this._findOrThrow(id);
    if (task.assigneeId !== actor.id) {
      throw new ForbiddenException('Anda bukan petugas yang ditugaskan pada tugas ini.');
    }

    const incompleteItems = await this.checklistService.getIncompleteMandatoryItems(id);
    if (incompleteItems.length > 0) {
      throw new BadRequestException({
        message: 'Masih ada bukti wajib yang belum lengkap.',
        incompleteItems, // Frontend menampilkan daftar ini secara spesifik, bukan pesan generik
      });
    }

    return this.transitionStatus(id, 'PENDING_VERIFICATION', actor);
  }

  /// Dipanggil VERIFIKATOR/SUPER_ADMIN - lihat Verification Workspace
  /// (Bagian 15 dokumen spesifikasi).
  async approve(id: string, actor: AuthenticatedUser) {
    const task = await this.transitionStatus(id, 'VERIFIED', actor);

    await this.audit.log({
      actorId: actor.id,
      action: 'TASK_APPROVED',
      entity: 'Task_SPPD',
      entityId: task.id,
    });

    await this.notifications.notify({
      userId: task.assigneeId,
      type: 'TASK_APPROVED',
      title: 'Tugas disetujui',
      body: `Tugas ${task.taskName} telah disetujui.`,
      relatedTaskId: task.id,
    });

    return task;
  }

  /// requestRevision
  /// ----------------------------------------------------------------------
  /// WAJIB disertai catatan spesifik (Bagian 22: "Nota BBM - Nominal
  /// kurang jelas") - tanpa ini Pegawai tidak tahu apa yang perlu
  /// diperbaiki, hanya melihat status berubah. Catatan disimpan permanen
  /// di Task_Revision_Note (riwayat, bukan cuma field tunggal yang
  /// tertimpa jika direvisi berkali-kali) dan diikutsertakan di
  /// notifikasi ke Pegawai.
  /// ----------------------------------------------------------------------
  async requestRevision(id: string, dto: RevisionNoteDto, actor: AuthenticatedUser) {
    const task = await this.transitionStatus(id, 'REVISION_NEEDED', actor);
    await this._recordRevisionNote(task.id, dto.note, 'REVISION_NEEDED', actor);

    await this.notifications.notify({
      userId: task.assigneeId,
      type: 'REVISION_NEEDED',
      title: 'Perlu diperbaiki',
      body: `Ada bagian yang perlu diperbaiki pada tugas ${task.taskName}: ${dto.note}`,
      relatedTaskId: task.id,
    });

    return this.findOne(task.id, actor);
  }

  async reject(id: string, dto: RevisionNoteDto, actor: AuthenticatedUser) {
    const task = await this.transitionStatus(id, 'REJECTED', actor);
    await this._recordRevisionNote(task.id, dto.note, 'REJECTED', actor);

    await this.notifications.notify({
      userId: task.assigneeId,
      type: 'TASK_REJECTED',
      title: 'Tugas ditolak',
      body: `Tugas ${task.taskName} ditolak: ${dto.note}`,
      relatedTaskId: task.id,
    });

    return this.findOne(task.id, actor);
  }

  private async _recordRevisionNote(
    taskId: string,
    note: string,
    status: TaskStatus,
    actor: AuthenticatedUser,
  ) {
    await this.prisma.task_Revision_Note.create({
      data: { taskId, actorId: actor.id, note, status },
    });

    await this.audit.log({
      actorId: actor.id,
      action: status === 'REJECTED' ? 'TASK_REJECTED' : 'TASK_REVISION_REQUESTED',
      entity: 'Task_SPPD',
      entityId: taskId,
      metadata: { note },
    });
  }

  /// Dipanggil PEGAWAI setelah REVISION_NEEDED, mengirim ulang untuk
  /// direview - transisi sama seperti submitForVerification pertama
  /// kali, tapi dari status awal yang berbeda (REVISION_NEEDED bukan
  /// ONGOING) - ALLOWED_TRANSITIONS sudah menangani keduanya karena
  /// tujuannya sama-sama PENDING_VERIFICATION.
  async resubmitAfterRevision(id: string, actor: AuthenticatedUser) {
    const task = await this._findOrThrow(id);
    if (task.assigneeId !== actor.id) {
      throw new ForbiddenException('Anda bukan petugas yang ditugaskan pada tugas ini.');
    }
    return this.transitionStatus(id, 'PENDING_VERIFICATION', actor);
  }

  /// Dipanggil BENDAHARA/ADMIN setelah LPJ terbit - lihat LPJ Generator
  /// (menyusul, modul documents).
  async complete(id: string, actor: AuthenticatedUser) {
    const task = await this.transitionStatus(id, 'COMPLETED', actor);

    await this.audit.log({
      actorId: actor.id,
      action: 'TASK_COMPLETED',
      entity: 'Task_SPPD',
      entityId: task.id,
    });

    return task;
  }

  private async _findOrThrow(id: string) {
    const task = await this.prisma.task_SPPD.findUnique({ where: { id } });
    if (!task) {
      throw new NotFoundException('Tugas tidak ditemukan.');
    }
    return task;
  }

  /// Format: TL-YYYYMM-XXXX, mis. TL-202608-0007. Sequence dihitung
  /// per bulan berjalan berdasarkan jumlah tugas yang sudah dibuat
  /// bulan ini - CATATAN: pendekatan count() ini punya celah race
  /// condition kecil di concurrency tinggi; untuk skala produksi lebih
  /// aman pakai PostgreSQL SEQUENCE atau constraint unique dengan retry.
  private async _generateTaskCode(): Promise<string> {
    const now = new Date();
    const yearMonth = `${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}`;

    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const count = await this.prisma.task_SPPD.count({
      where: { createdAt: { gte: startOfMonth } },
    });

    const sequence = String(count + 1).padStart(4, '0');
    return `TL-${yearMonth}-${sequence}`;
  }

  private _defaultInclude() {
    return {
      assignee: {
        select: { id: true, fullName: true, email: true, instansiName: true },
      },
      creator: {
        select: { id: true, fullName: true, email: true },
      },
      _count: {
        select: {
          geotagPhotos: true,
          expenseNotes: true,
          checklistItems: true,
        },
      },
      revisionNotes: {
        orderBy: { createdAt: 'desc' as const },
        include: { actor: { select: { id: true, fullName: true } } },
      },
    };
  }
}
