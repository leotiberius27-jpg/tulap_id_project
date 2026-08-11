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
import { CreateTaskDto } from './dto/create-task.dto';
import { QueryTasksDto } from './dto/query-tasks.dto';
import { UpdateTaskDto } from './dto/update-task.dto';

/// Peta transisi status yang SAH - state machine sederhana untuk
/// mencegah lompatan status yang tidak masuk akal (mis. DRAFT langsung
/// ke VERIFIED tanpa melalui submit & review). Selaras dengan alur
/// "Terima Tugas -> ... -> Verifikasi -> Revisi -> Disetujui" di
/// dokumen requirement awal.
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

    return this.prisma.task_SPPD.create({
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
    return this.transitionStatus(id, 'VERIFIED', actor);
  }

  async requestRevision(id: string, actor: AuthenticatedUser) {
    return this.transitionStatus(id, 'REVISION_NEEDED', actor);
  }

  async reject(id: string, actor: AuthenticatedUser) {
    return this.transitionStatus(id, 'REJECTED', actor);
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
    return this.transitionStatus(id, 'COMPLETED', actor);
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
    };
  }
}
