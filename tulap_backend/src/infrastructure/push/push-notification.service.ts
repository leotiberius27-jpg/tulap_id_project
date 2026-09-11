import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { App, cert, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

/**
 * PushNotificationService
 * ----------------------------------------------------------------------
 * Pengiriman push notification nyata via Firebase Cloud Messaging
 * (firebase-admin), dikonfigurasi lewat FIREBASE_SERVICE_ACCOUNT_JSON -
 * persis pola MailerService/S3StorageService: TIDAK ADA kredensial
 * hardcode/palsu.
 *
 * Jika env var itu kosong (belum dikonfigurasi operator), service ini
 * TIDAK melempar error - `isConfigured` bernilai false dan
 * NotificationsService.notify() melewati langkah push sepenuhnya,
 * Notification in-app tetap tersimpan seperti biasa. Push notification
 * SELALU best-effort: kegagalan mengirim push TIDAK PERNAH boleh
 * menggagalkan alur utama yang memanggilnya.
 * ----------------------------------------------------------------------
 */
@Injectable()
export class PushNotificationService {
  private readonly logger = new Logger(PushNotificationService.name);
  private app: App | null = null;

  constructor(private readonly config: ConfigService) {
    const raw = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON');
    if (raw) {
      try {
        const credentials = JSON.parse(raw);
        this.app = initializeApp(
          { credential: cert(credentials) },
          'tulap-push',
        );
      } catch (err) {
        this.logger.error(
          `FIREBASE_SERVICE_ACCOUNT_JSON tidak valid - push notification dinonaktifkan: ${err}`,
        );
      }
    }
  }

  get isConfigured(): boolean {
    return this.app !== null;
  }

  /// Mengirim satu push yang sama ke banyak token sekaligus (satu user
  /// bisa punya lebih dari satu perangkat terdaftar). Mengembalikan token
  /// yang ditolak FCM sebagai tidak valid/kadaluarsa - pemanggil
  /// bertanggung jawab menghapusnya dari tabel device_tokens supaya
  /// tidak dicoba lagi di notifikasi berikutnya.
  async sendToTokens(
    tokens: string[],
    payload: { title: string; body: string; data?: Record<string, string> },
  ): Promise<string[]> {
    if (!this.app || tokens.length === 0) return [];

    try {
      const response = await getMessaging(this.app).sendEachForMulticast({
        tokens,
        notification: { title: payload.title, body: payload.body },
        data: payload.data,
        android: { priority: 'high' },
      });

      const staleTokens: string[] = [];
      response.responses.forEach((res, idx) => {
        if (res.success) return;
        const code = res.error?.code;
        if (
          code === 'messaging/registration-token-not-registered' ||
          code === 'messaging/invalid-registration-token' ||
          code === 'messaging/invalid-argument'
        ) {
          staleTokens.push(tokens[idx]);
        } else {
          this.logger.warn(`Push gagal ke satu token: ${res.error?.message}`);
        }
      });
      return staleTokens;
    } catch (err) {
      this.logger.error(`Push notification gagal dikirim: ${err}`);
      return [];
    }
  }
}
