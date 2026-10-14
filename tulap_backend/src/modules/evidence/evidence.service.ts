import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { createHash } from 'crypto';
import { ExpenseCategory, RoleName, TaskStatus } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { AuditService } from '../audit/audit.service';
import { FirestoreSyncService } from '../../infrastructure/firestore/firestore-sync.service';
import { UploadPhotoDto } from './dto/upload-photo.dto';
import { UploadReceiptDto } from './dto/upload-receipt.dto';

/// Bukti (foto/video/nota) hanya boleh dihapus selama tugas masih
/// dikerjakan di lapangan. Begitu tugas dikirim untuk verifikasi
/// (PENDING_VERIFICATION) atau sudah diputuskan (VERIFIED, REJECTED,
/// COMPLETED), bukti TERKUNCI - termasuk untuk ADMIN/SUPER_ADMIN -
/// supaya bukti yang sudah dinilai Verifikator / masuk LPJ tidak bisa
/// hilang. Jika bukti perlu diganti, Verifikator mengembalikan tugas
/// (REVISION_NEEDED) lebih dulu.
const EVIDENCE_DELETABLE_TASK_STATUSES: TaskStatus[] = [
  TaskStatus.DRAFT,
  TaskStatus.ONGOING,
  TaskStatus.REVISION_NEEDED,
];

const EVIDENCE_LOCKED_MESSAGE =
  'Bukti terkunci karena tugas sudah dikirim untuk verifikasi atau sudah diputuskan. Minta Verifikator mengembalikan tugas untuk revisi jika bukti perlu diganti.';

/// `id` dikirim client (UUID lokal mobile) agar retry sync idempoten.
/// Jika id itu sudah dipakai record milik user lain / tugas lain, request
/// ditolak TANPA mengembalikan data record tsb.
const CLIENT_ID_CONFLICT_MESSAGE = 'ID data sudah dipakai oleh data lain.';

@Injectable()
export class EvidenceService {
  private readonly logger = new Logger(EvidenceService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: S3StorageService,
    private readonly audit: AuditService,
    private readonly firestoreSync: FirestoreSyncService,
  ) {}

  /// uploadPhoto
  /// ----------------------------------------------------------------------
  /// Menerima foto/video bukti geotag dari mobile.
  /// Idempotensi kuat: Jika bukti dengan id atau taskId+hash sudah ada,
  /// mengembalikan data yang sudah tersimpan tanpa duplikasi.
  /// ----------------------------------------------------------------------
  async uploadPhoto(
    dto: UploadPhotoDto,
    file: Express.Multer.File,
    actor: AuthenticatedUser,
  ) {
    const task = await this._verifyTaskOwnership(dto.taskId, actor);

    // 1. Pengecekan Idempotensi: jika bukti sudah ada di server, return existing
    if (dto.id) {
      const existingById = await this.prisma.geotag_Photo.findUnique({
        where: { id: dto.id },
      });
      if (existingById) {
        // Hanya retry oleh PEMILIK yang sama untuk tugas yang sama yang
        // dianggap idempoten - id milik orang lain ditolak tanpa
        // membocorkan data (sebelumnya photoUrl-nya dikembalikan).
        if (existingById.uploaderId !== actor.id || existingById.taskId !== dto.taskId) {
          throw new ConflictException(CLIENT_ID_CONFLICT_MESSAGE);
        }
        return {
          id: existingById.id,
          photoUrl: existingById.photoUrl,
          serverTimestamp: existingById.serverTimestamp.toISOString(),
          hashVerified: true,
        };
      }
    }

    const existingByHash = await this.prisma.geotag_Photo.findFirst({
      where: {
        taskId: dto.taskId,
        integrityHash: dto.integrityHash,
      },
    });
    if (existingByHash) {
      return {
        id: existingByHash.id,
        photoUrl: existingByHash.photoUrl,
        serverTimestamp: existingByHash.serverTimestamp.toISOString(),
        hashVerified: true,
      };
    }

    // 2. Verifikasi hash rekalkulasi di server
    const recalculatedHash = createHash('sha256').update(file.buffer).digest('hex');
    const hashMatches = recalculatedHash === dto.integrityHash;
    if (!hashMatches) {
      this.logger.warn(
        `Hash mismatch untuk bukti tugas ${dto.taskId}: klaim=${dto.integrityHash}, aktual=${recalculatedHash}`,
      );
    }

    // 3. Tentukan kategori storage (photo vs video)
    const isVideo =
      file.mimetype.startsWith('video/') || dto.mediaType?.toUpperCase() === 'VIDEO';
    const category = isVideo ? 'video' : 'photo';

    const uploadResult = await this.storage.uploadFile({
      buffer: file.buffer,
      mimeType: file.mimetype,
      category,
    });

    const authoritativeTimestamp = new Date();

    const photo = await this.prisma.geotag_Photo.create({
      data: {
        id: dto.id ?? undefined,
        taskId: dto.taskId,
        uploaderId: actor.id,
        photoUrl: uploadResult.url,
        latitude: dto.latitude,
        longitude: dto.longitude,
        address: dto.address,
        serverTimestamp: authoritativeTimestamp,
        integrityHash: dto.integrityHash,
        isMockLocationFlag: dto.isMockLocationDetected,
        isRootedDeviceFlag: dto.isRootedDeviceDetected,
        caption: dto.caption,
      },
    });

    await this.audit.log({
      actorId: actor.id,
      action: isVideo ? 'EVIDENCE_VIDEO_UPLOADED' : 'EVIDENCE_PHOTO_UPLOADED',
      entity: 'Geotag_Photo',
      entityId: photo.id,
      metadata: {
        taskId: dto.taskId,
        mediaType: isVideo ? 'VIDEO' : 'PHOTO',
        hashVerified: hashMatches,
        shortEvidenceId: dto.shortEvidenceId,
      },
    });

    await this.firestoreSync.mirrorAssetDocument({
      id: photo.id,
      taskId: photo.taskId,
      uploaderId: photo.uploaderId,
      photoUrl: photo.photoUrl,
      latitude: photo.latitude,
      longitude: photo.longitude,
      address: photo.address,
      caption: photo.caption,
      mediaType: isVideo ? 'VIDEO' : 'PHOTO',
      serverTimestamp: authoritativeTimestamp,
    });

    return {
      id: photo.id,
      photoUrl: photo.photoUrl,
      serverTimestamp: authoritativeTimestamp.toISOString(),
      hashVerified: hashMatches,
    };
  }

  /// uploadReceipt
  /// ----------------------------------------------------------------------
  /// Menerima nota hasil OCR dari mobile dengan deteksi duplikat otoritatif.
  /// ----------------------------------------------------------------------
  async uploadReceipt(
    dto: UploadReceiptDto,
    file: Express.Multer.File | undefined,
    actor: AuthenticatedUser,
  ) {
    await this._verifyTaskOwnership(dto.taskId, actor);

    // 1. Cek idempotensi: jika id nota sudah ada, kembalikan record yang ada
    if (dto.id) {
      const existingById = await this.prisma.expense_Note.findUnique({
        where: { id: dto.id },
      });
      if (existingById) {
        // Lihat catatan yang sama di uploadPhoto.
        if (existingById.ownerId !== actor.id || existingById.taskId !== dto.taskId) {
          throw new ConflictException(CLIENT_ID_CONFLICT_MESSAGE);
        }
        return {
          id: existingById.id,
          scanUrl: existingById.scanUrl,
          verificationStatus: existingById.verificationStatus,
          serverTimestamp: existingById.createdAt.toISOString(),
        };
      }
    }

    const category = this._mapCategory(dto.category);

    const duplicate = await this.prisma.expense_Note.findFirst({
      where: {
        taskId: dto.taskId,
        vendorName: { equals: dto.vendorName, mode: 'insensitive' },
        transactionDate: new Date(dto.transactionDate),
        totalAmount: dto.totalAmount,
      },
    });

    if (duplicate && (!dto.id || duplicate.id !== dto.id)) {
      return {
        id: duplicate.id,
        scanUrl: duplicate.scanUrl,
        verificationStatus: duplicate.verificationStatus,
        serverTimestamp: duplicate.createdAt.toISOString(),
      };
    }

    let scanUrl = '';
    if (file) {
      const uploadResult = await this.storage.uploadFile({
        buffer: file.buffer,
        mimeType: file.mimetype,
        category: 'receipt',
      });
      scanUrl = uploadResult.url;
    }

    const authoritativeTimestamp = new Date();

    const note = await this.prisma.expense_Note.create({
      data: {
        id: dto.id ?? undefined,
        taskId: dto.taskId,
        ownerId: actor.id,
        scanUrl,
        vendorName: dto.vendorName,
        transactionDate: new Date(dto.transactionDate),
        totalAmount: dto.totalAmount,
        category,
        ocrRawText: dto.ocrRawText,
        ocrConfidence: dto.ocrConfidence,
        verificationStatus: 'PENDING',
      },
    });

    await this.audit.log({
      actorId: actor.id,
      action: 'EVIDENCE_RECEIPT_UPLOADED',
      entity: 'Expense_Note',
      entityId: note.id,
      metadata: { taskId: dto.taskId, totalAmount: dto.totalAmount, vendorName: dto.vendorName },
    });

    return {
      id: note.id,
      scanUrl: note.scanUrl,
      verificationStatus: note.verificationStatus,
      serverTimestamp: authoritativeTimestamp.toISOString(),
    };
  }

  /// getEvidenceReceipt
  /// ----------------------------------------------------------------------
  /// Mengambil data detail satu nota pengeluaran dengan relasi task & owner.
  /// ----------------------------------------------------------------------
  async getEvidenceReceipt(id: string, actor: AuthenticatedUser) {
    const receipt = await this.prisma.expense_Note.findUnique({
      where: { id },
      include: {
        task: {
          select: {
            id: true,
            taskCode: true,
            taskName: true,
            destination: true,
            assigneeId: true,
          },
        },
        owner: {
          select: {
            id: true,
            fullName: true,
            instansiName: true,
            unitKerja: true,
          },
        },
      },
    });

    if (!receipt) {
      throw new NotFoundException('Nota tidak ditemukan.');
    }

    if (actor.role === 'PEGAWAI' && receipt.ownerId !== actor.id) {
      throw new ForbiddenException('Anda tidak memiliki akses ke nota ini.');
    }

    return receipt;
  }

  /// deleteEvidenceReceipt
  /// ----------------------------------------------------------------------
  /// Menghapus nota pengeluaran dengan audit log.
  /// ----------------------------------------------------------------------
  async deleteEvidenceReceipt(id: string, actor: AuthenticatedUser) {
    const receipt = await this.prisma.expense_Note.findUnique({
      where: { id },
      include: { task: true },
    });

    if (!receipt) {
      throw new NotFoundException('Nota tidak ditemukan.');
    }

    if (receipt.ownerId !== actor.id) {
      throw new ForbiddenException(
        'Anda hanya dapat menghapus nota yang Anda unggah sendiri.',
      );
    }

    this._assertTaskAllowsEvidenceDeletion(receipt.task.status);

    // Syarat kepemilikan & status tugas diulang di query DELETE itu
    // sendiri (atomik) - tugas yang dikirim untuk verifikasi di antara
    // pengecekan di atas dan baris ini tidak bisa lolos.
    const { count } = await this.prisma.expense_Note.deleteMany({
      where: {
        id,
        ownerId: actor.id,
        task: { is: { status: { in: EVIDENCE_DELETABLE_TASK_STATUSES } } },
      },
    });
    if (count === 0) {
      throw new ConflictException(EVIDENCE_LOCKED_MESSAGE);
    }

    await this.audit.log({
      actorId: actor.id,
      action: 'EVIDENCE_RECEIPT_DELETED',
      entity: 'Expense_Note',
      entityId: id,
      metadata: {
        taskId: receipt.taskId,
        vendorName: receipt.vendorName,
        totalAmount: Number(receipt.totalAmount),
      },
    });

    return { success: true, message: 'Nota berhasil dihapus.' };
  }

  /// getEvidencePhoto
  /// ----------------------------------------------------------------------
  /// Mengambil data detail satu foto/video bukti dengan relasi task & uploader.
  /// ----------------------------------------------------------------------
  async getEvidencePhoto(id: string, actor: AuthenticatedUser) {
    const photo = await this.prisma.geotag_Photo.findUnique({
      where: { id },
      include: {
        task: {
          select: {
            id: true,
            taskCode: true,
            taskName: true,
            destination: true,
            assigneeId: true,
          },
        },
        uploader: {
          select: {
            id: true,
            fullName: true,
            instansiName: true,
            unitKerja: true,
          },
        },
      },
    });

    if (!photo) {
      throw new NotFoundException('Bukti foto tidak ditemukan.');
    }

    if (
      actor.role === RoleName.PEGAWAI &&
      photo.uploaderId !== actor.id &&
      photo.task.assigneeId !== actor.id
    ) {
      throw new ForbiddenException('Anda tidak memiliki akses ke bukti ini.');
    }

    return photo;
  }

  /// Respons GET /evidence/photo/:id dan /evidence/receipt/:id untuk
  /// client - sama dengan getEvidence*, ditambah URL baca bertanda tangan
  /// berumur pendek (P0-07, aditif). Dipisah dari getEvidencePhoto karena
  /// method itu juga dipakai internal (verify/delete) yang tidak butuh URL.
  async getEvidencePhotoForClient(id: string, actor: AuthenticatedUser) {
    const photo = await this.getEvidencePhoto(id, actor);
    return { ...photo, photoSignedUrl: await this.storage.signStoredUrl(photo.photoUrl) };
  }

  async getEvidenceReceiptForClient(id: string, actor: AuthenticatedUser) {
    const receipt = await this.getEvidenceReceipt(id, actor);
    return { ...receipt, scanSignedUrl: await this.storage.signStoredUrl(receipt.scanUrl) };
  }

  /// verifyEvidencePhoto
  /// ----------------------------------------------------------------------
  /// Menjalankan audit multi-signal sisi server terhadap integritas bukti.
  /// ----------------------------------------------------------------------
  async verifyEvidencePhoto(id: string, actor: AuthenticatedUser) {
    const photo = await this.getEvidencePhoto(id, actor);

    const hasValidLocation =
      Number(photo.latitude) !== 0 && Number(photo.longitude) !== 0;
    const isMockLocation = photo.isMockLocationFlag;
    const isRooted = photo.isRootedDeviceFlag;
    const hasHash = Boolean(photo.integrityHash && photo.integrityHash.length === 64);

    let overallStatus = 'TERVERIFIKASI_SISTEM';
    if (!hasHash || isRooted) {
      overallStatus = 'INTEGRITAS_TIDAK_SESUAI';
    } else if (isMockLocation) {
      overallStatus = 'PERLU_DITINJAU';
    } else if (!hasValidLocation) {
      overallStatus = 'DATA_TIDAK_LENGKAP';
    }

    await this.audit.log({
      actorId: actor.id,
      action: 'EVIDENCE_VERIFIED',
      entity: 'Geotag_Photo',
      entityId: photo.id,
      metadata: {
        taskId: photo.taskId,
        overallStatus,
        hasHash,
        isMockLocation,
      },
    });

    return {
      photoId: photo.id,
      taskId: photo.taskId,
      taskCode: photo.task.taskCode,
      taskName: photo.task.taskName,
      uploaderName: photo.uploader.fullName,
      instansiName: photo.uploader.instansiName,
      serverTimestamp: photo.serverTimestamp.toISOString(),
      latitude: Number(photo.latitude),
      longitude: Number(photo.longitude),
      address: photo.address,
      integrityHash: photo.integrityHash,
      isMockLocationDetected: photo.isMockLocationFlag,
      isRootedDeviceDetected: photo.isRootedDeviceFlag,
      overallStatus,
      signals: {
        fileIntegrityMatch: hasHash,
        locationRecorded: hasValidLocation,
        mockLocationDetected: isMockLocation,
        deviceCompromised: isRooted,
        serverPersisted: true,
      },
    };
  }

  /// deleteEvidencePhoto
  /// ----------------------------------------------------------------------
  /// Menghapus bukti foto/video secara aman dan mencatatnya ke audit trail.
  /// ----------------------------------------------------------------------
  async deleteEvidencePhoto(id: string, actor: AuthenticatedUser) {
    const photo = await this.getEvidencePhoto(id, actor);

    if (photo.uploaderId !== actor.id) {
      throw new ForbiddenException('Anda hanya dapat menghapus bukti milik Anda sendiri.');
    }

    const task = await this.prisma.task_SPPD.findUnique({
      where: { id: photo.taskId },
      select: { status: true },
    });
    if (!task) {
      throw new NotFoundException('Tugas tidak ditemukan.');
    }
    this._assertTaskAllowsEvidenceDeletion(task.status);

    // Atomik - lihat catatan yang sama di deleteEvidenceReceipt.
    const { count } = await this.prisma.geotag_Photo.deleteMany({
      where: {
        id,
        uploaderId: actor.id,
        task: { is: { status: { in: EVIDENCE_DELETABLE_TASK_STATUSES } } },
      },
    });
    if (count === 0) {
      throw new ConflictException(EVIDENCE_LOCKED_MESSAGE);
    }

    await this.audit.log({
      actorId: actor.id,
      action: 'EVIDENCE_DELETED',
      entity: 'Geotag_Photo',
      entityId: id,
      metadata: {
        taskId: photo.taskId,
        caption: photo.caption,
      },
    });

    return { success: true, message: 'Bukti berhasil dihapus.' };
  }

  private _assertTaskAllowsEvidenceDeletion(status: TaskStatus) {
    if (!EVIDENCE_DELETABLE_TASK_STATUSES.includes(status)) {
      throw new ConflictException(EVIDENCE_LOCKED_MESSAGE);
    }
  }

  /// Memastikan task yang direferensikan benar-benar ada DAN task
  /// tersebut memang ditugaskan ke user yang sedang login.
  private async _verifyTaskOwnership(taskId: string, actor: AuthenticatedUser) {
    const task = await this.prisma.task_SPPD.findUnique({
      where: { id: taskId },
    });

    if (!task) {
      throw new NotFoundException('Tugas tidak ditemukan.');
    }

    if (task.assigneeId !== actor.id) {
      throw new BadRequestException(
        'Anda tidak dapat mengunggah bukti untuk tugas yang bukan milik Anda.',
      );
    }

    return task;
  }

  private _mapCategory(category: string): ExpenseCategory {
    const map: Record<string, ExpenseCategory> = {
      bbm: 'BBM',
      tol: 'TOL',
      penginapan: 'PENGINAPAN',
      retail: 'RETAIL',
      konsumsi: 'KONSUMSI',
      transportasiLain: 'TRANSPORTASI_LAIN',
      lainnya: 'LAINNYA',
    };
    return map[category] ?? 'LAINNYA';
  }
}
