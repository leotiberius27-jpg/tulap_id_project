import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

/**
 * MailerService
 * ----------------------------------------------------------------------
 * Pengiriman email nyata via SMTP (nodemailer), dikonfigurasi lewat
 * environment variable persis seperti S3StorageService (SMTP_HOST/PORT/
 * USER/PASSWORD/FROM) — tidak ada kredensial hardcode/palsu di sini.
 *
 * Jika SMTP_HOST kosong (belum dikonfigurasi oleh operator instansi),
 * service ini TIDAK berpura-pura berhasil mengirim — di development
 * kode reset di-log ke console agar alur tetap bisa diuji end-to-end
 * tanpa SMTP asli, di production method melempar error yang jelas
 * supaya operator tahu SMTP belum di-setup, bukan gagal diam-diam.
 * ----------------------------------------------------------------------
 */
@Injectable()
export class MailerService {
  private readonly logger = new Logger(MailerService.name);
  private transporter: nodemailer.Transporter | null = null;

  constructor(private readonly config: ConfigService) {
    const host = this.config.get<string>('SMTP_HOST');
    if (host) {
      this.transporter = nodemailer.createTransport({
        host,
        port: Number(this.config.get<string>('SMTP_PORT', '587')),
        secure: Number(this.config.get<string>('SMTP_PORT', '587')) === 465,
        auth: {
          user: this.config.get<string>('SMTP_USER'),
          pass: this.config.get<string>('SMTP_PASSWORD'),
        },
      });
    }
  }

  get isConfigured(): boolean {
    return this.transporter !== null;
  }

  async sendPasswordResetCode(email: string, code: string): Promise<void> {
    const subject = 'Kode Reset Kata Sandi Tulap.id';
    const text =
      `Kode reset kata sandi Anda: ${code}\n\n` +
      `Kode ini berlaku selama 15 menit. Jika Anda tidak meminta reset ` +
      `kata sandi, abaikan email ini.`;

    if (!this.transporter) {
      // Belum ada SMTP asli dikonfigurasi (SMTP_HOST kosong di .env) -
      // di development, log kode ke console supaya alur reset password
      // tetap bisa diuji end-to-end tanpa mailbox sungguhan. Di
      // production ini melempar error yang jelas, BUKAN diam-diam
      // "berhasil" padahal email tidak pernah terkirim.
      if (this.config.get<string>('NODE_ENV') !== 'production') {
        this.logger.warn(
          `[DEV] SMTP belum dikonfigurasi - kode reset untuk ${email}: ${code}`,
        );
        return;
      }
      throw new Error(
        'SMTP belum dikonfigurasi (SMTP_HOST kosong) - email tidak dapat dikirim.',
      );
    }

    await this.transporter.sendMail({
      from: this.config.get<string>('SMTP_FROM', 'Tulap.id <no-reply@tulap.id>'),
      to: email,
      subject,
      text,
    });
  }
}
