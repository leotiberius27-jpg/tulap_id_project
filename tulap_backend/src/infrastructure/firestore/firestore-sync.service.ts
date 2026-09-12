import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { cert, initializeApp } from 'firebase-admin/app';
import { Firestore, getFirestore } from 'firebase-admin/firestore';

/**
 * FirestoreSyncService
 * ----------------------------------------------------------------------
 * PostgreSQL TETAP satu-satunya sumber kebenaran untuk seluruh app -
 * service ini HANYA membuat salinan realtime tambahan di Cloud Firestore
 * untuk dua hal yang diminta eksplisit (bukan migrasi, murni cermin
 * tambahan):
 *   - `activity_reports` - laporan lapangan (Task_SPPD) begitu PEGAWAI
 *     menekan "Kirim Tugas" (TasksService.submitForVerification).
 *   - `asset_documents` - dokumen/foto bukti aset daerah begitu berhasil
 *     diunggah (EvidenceService.uploadPhoto).
 *
 * Sama seperti PushNotificationService: dikonfigurasi lewat
 * FIREBASE_SERVICE_ACCOUNT_JSON (kredensial yang SAMA, satu service
 * account Firebase bisa dipakai untuk Cloud Messaging maupun Firestore
 * sekaligus - tidak perlu secret baru). Jika kosong atau Cloud Firestore
 * API/database belum diaktifkan di Firebase Console, `isConfigured`
 * bernilai false dan seluruh method di sini no-op diam-diam - TIDAK
 * PERNAH melempar, kegagalan cermin ke Firestore tidak boleh
 * menggagalkan alur utama (submit laporan / upload bukti tetap
 * tersimpan normal di PostgreSQL terlepas dari ini).
 * ----------------------------------------------------------------------
 */
@Injectable()
export class FirestoreSyncService {
  private readonly logger = new Logger(FirestoreSyncService.name);
  private db: Firestore | null = null;

  constructor(private readonly config: ConfigService) {
    const raw = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON');
    if (raw) {
      try {
        const credentials = JSON.parse(raw);
        const app = initializeApp(
          { credential: cert(credentials) },
          'tulap-firestore',
        );
        this.db = getFirestore(app);
      } catch (err) {
        this.logger.error(
          `FIREBASE_SERVICE_ACCOUNT_JSON tidak valid - sinkronisasi Firestore dinonaktifkan: ${err}`,
        );
      }
    }
  }

  get isConfigured(): boolean {
    return this.db !== null;
  }

  async mirrorActivityReport(task: {
    id: string;
    taskCode: string;
    taskName: string;
    destination: string;
    description: string | null;
    status: string;
    assigneeId: string;
    assigneeName: string;
    creatorId: string;
    startDate: Date;
    endDate: Date;
    budgetAmount: unknown;
    realizedAmount: unknown;
  }): Promise<void> {
    if (!this.db) return;
    try {
      await this.db
        .collection('activity_reports')
        .doc(task.id)
        .set(
          {
            taskCode: task.taskCode,
            taskName: task.taskName,
            destination: task.destination,
            description: task.description,
            status: task.status,
            assigneeId: task.assigneeId,
            assigneeName: task.assigneeName,
            creatorId: task.creatorId,
            startDate: task.startDate.toISOString(),
            endDate: task.endDate.toISOString(),
            budgetAmount: Number(task.budgetAmount),
            realizedAmount: Number(task.realizedAmount),
            submittedAt: new Date().toISOString(),
          },
          { merge: true },
        );
    } catch (err) {
      this.logger.warn(
        `Gagal menyalin laporan ${task.id} ke Firestore (PostgreSQL tetap tersimpan normal): ${err}`,
      );
    }
  }

  async mirrorAssetDocument(photo: {
    id: string;
    taskId: string;
    uploaderId: string;
    photoUrl: string;
    latitude: unknown;
    longitude: unknown;
    address: string | null;
    caption: string | null;
    mediaType: string;
    serverTimestamp: Date;
  }): Promise<void> {
    if (!this.db) return;
    try {
      await this.db
        .collection('asset_documents')
        .doc(photo.id)
        .set(
          {
            taskId: photo.taskId,
            uploaderId: photo.uploaderId,
            photoUrl: photo.photoUrl,
            latitude: photo.latitude != null ? Number(photo.latitude) : null,
            longitude: photo.longitude != null ? Number(photo.longitude) : null,
            address: photo.address,
            caption: photo.caption,
            mediaType: photo.mediaType,
            serverTimestamp: photo.serverTimestamp.toISOString(),
          },
          { merge: true },
        );
    } catch (err) {
      this.logger.warn(
        `Gagal menyalin dokumen aset ${photo.id} ke Firestore (PostgreSQL/S3 tetap tersimpan normal): ${err}`,
      );
    }
  }
}
