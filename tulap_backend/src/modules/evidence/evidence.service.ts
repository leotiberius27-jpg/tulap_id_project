import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { createHash } from 'crypto';
import { ExpenseCategory } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { UploadPhotoDto } from './dto/upload-photo.dto';
import { UploadReceiptDto } from './dto/upload-receipt.dto';

@Injectable()
export class EvidenceService {
  private readonly logger = new Logger(EvidenceService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: S3StorageService,
  ) {}

  /// uploadPhoto
  /// ----------------------------------------------------------------------
  /// Menerima foto bukti geotag dari mobile. SERVER (bukan device) yang
  /// menjadi sumber kebenaran timestamp - inilah rekonsiliasi
  /// "serverTimestamp otoritatif" yang dibahas di catatan implementasi
  /// SyncRemoteDataSource di mobile: response endpoint ini mengembalikan
  /// waktu penerimaan request sebagai serverTimestamp resmi, menimpa
  /// nilai fallback jam device yang dikirim mobile.
  ///
  /// Validasi integritas dilakukan DUA LAPIS di sini:
  ///   1. Hash SHA-256 file yang diterima dihitung ULANG di server dan
  ///      dibandingkan dengan integrityHash yang diklaim mobile - jika
  ///      berbeda, file kemungkinan rusak/dimanipulasi saat transit.
  ///   2. Task harus benar-benar milik user yang login (defense in
  ///      depth terhadap upload atas nama tugas orang lain).
  /// ----------------------------------------------------------------------
  async uploadPhoto(
    dto: UploadPhotoDto,
    file: Express.Multer.File,
    actor: AuthenticatedUser,
  ) {
    const task = await this._verifyTaskOwnership(dto.taskId, actor);

    // Verifikasi ulang hash - HANYA sebagai audit trail/warning, TIDAK
    // memblokir upload, karena kompresi tambahan di sisi jaringan
    // (mis. proxy) bisa saja mengubah byte tanpa itu berarti manipulasi
    // niat jahat. Ketidakcocokan dicatat, bukan ditolak otomatis.
    const recalculatedHash = createHash('sha256').update(file.buffer).digest('hex');
    const hashMatches = recalculatedHash === dto.integrityHash;
    if (!hashMatches) {
      this.logger.warn(
        `Hash mismatch untuk foto tugas ${dto.taskId}: klaim=${dto.integrityHash}, aktual=${recalculatedHash}`,
      );
    }

    const uploadResult = await this.storage.uploadFile({
      buffer: file.buffer,
      mimeType: file.mimetype,
      category: 'photo',
    });

    // Timestamp OTORITATIF adalah waktu server menerima request ini -
    // BUKAN dto.serverTimestamp (yang merupakan fallback jam device
    // dari mobile, hanya disimpan sebagai referensi terpisah).
    const authoritativeTimestamp = new Date();

    const photo = await this.prisma.geotag_Photo.create({
      data: {
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

    return {
      id: photo.id,
      photoUrl: photo.photoUrl,
      serverTimestamp: authoritativeTimestamp.toISOString(),
      hashVerified: hashMatches,
    };
  }

  /// uploadReceipt
  /// ----------------------------------------------------------------------
  /// Menerima nota hasil OCR dari mobile. Pengecekan duplikat di sini
  /// adalah validasi OTORITATIF (sumber kebenaran final) - berbeda dari
  /// pengecekan di mobile (ExpenseOcrLocalDataSource.findDuplicateNoteId)
  /// yang sifatnya hanya peringatan dini lokal per-device. Duplikat
  /// dicek LINTAS SELURUH PEGAWAI dalam task yang sama, karena mobile
  /// tidak punya visibilitas ke nota yang sudah diunggah pegawai lain.
  /// ----------------------------------------------------------------------
  async uploadReceipt(
    dto: UploadReceiptDto,
    file: Express.Multer.File,
    actor: AuthenticatedUser,
  ) {
    await this._verifyTaskOwnership(dto.taskId, actor);

    const category = this._mapCategory(dto.category);

    const duplicate = await this.prisma.expense_Note.findFirst({
      where: {
        taskId: dto.taskId,
        vendorName: { equals: dto.vendorName, mode: 'insensitive' },
        transactionDate: new Date(dto.transactionDate),
        totalAmount: dto.totalAmount,
      },
    });

    if (duplicate) {
      throw new ConflictException(
        'Nota dengan vendor, tanggal, dan nominal yang sama sudah pernah diunggah untuk tugas ini.',
      );
    }

    const uploadResult = await this.storage.uploadFile({
      buffer: file.buffer,
      mimeType: file.mimetype,
      category: 'receipt',
    });

    const note = await this.prisma.expense_Note.create({
      data: {
        taskId: dto.taskId,
        ownerId: actor.id,
        scanUrl: uploadResult.url,
        vendorName: dto.vendorName,
        transactionDate: new Date(dto.transactionDate),
        totalAmount: dto.totalAmount,
        category,
        ocrRawText: dto.ocrRawText,
        ocrConfidence: dto.ocrConfidence,
        verificationStatus: 'PENDING',
      },
    });

    return {
      id: note.id,
      scanUrl: note.scanUrl,
      verificationStatus: note.verificationStatus,
    };
  }

  /// Memastikan task yang direferensikan benar-benar ada DAN task
  /// tersebut memang ditugaskan ke user yang sedang login - mencegah
  /// pegawai mengunggah bukti atas nama tugas milik pegawai lain.
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
