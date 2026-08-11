import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

/**
 * PrismaService
 * ----------------------------------------------------------------------
 * Service terpusat untuk koneksi database PostgreSQL via Prisma ORM.
 * Di-inject ke seluruh modul yang butuh akses database (Auth, Users,
 * Tasks, Geotag Photos, Expense Notes, dsb).
 *
 * Menerapkan lifecycle hook NestJS agar koneksi dibuka saat modul
 * di-inisialisasi dan ditutup dengan bersih (graceful shutdown) saat
 * aplikasi dimatikan — penting untuk mencegah connection leak.
 * ----------------------------------------------------------------------
 */
@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);

  constructor() {
    super({
      // Log query di environment development untuk membantu debugging,
      // di production cukup log error & warning demi performa.
      log:
        process.env.NODE_ENV === 'development'
          ? ['query', 'info', 'warn', 'error']
          : ['warn', 'error'],
    });
  }

  async onModuleInit() {
    try {
      await this.$connect();
      this.logger.log('Koneksi database PostgreSQL berhasil dibuka.');
    } catch (error) {
      this.logger.error('Gagal terhubung ke database:', error);
      throw error;
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
    this.logger.log('Koneksi database PostgreSQL ditutup.');
  }
}
