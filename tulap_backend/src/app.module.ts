import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { PrismaModule } from './infrastructure/prisma/prisma.module';
import { StorageModule } from './infrastructure/storage/storage.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { TasksModule } from './modules/tasks/tasks.module';
import { ChecklistModule } from './modules/checklist/checklist.module';
import { EvidenceModule } from './modules/evidence/evidence.module';
import { LpjModule } from './modules/lpj/lpj.module';
import { AuditModule } from './modules/audit/audit.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { TravelModule } from './modules/travel/travel.module';
import { SearchModule } from './modules/search/search.module';
import { DashboardModule } from './modules/dashboard/dashboard.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RolesGuard } from './common/guards/roles.guard';

@Module({
  imports: [
    // isGlobal: true -> ConfigService bisa langsung di-inject ke modul
    // manapun tanpa perlu import ConfigModule berulang kali.
    ConfigModule.forRoot({ isGlobal: true }),
    // Rate limiting global (Bagian 30: "Rate limiting ... untuk aksi
    // sensitif") - default 100 request/menit per IP, endpoint tertentu
    // (login) memakai @Throttle() yang lebih ketat langsung di controller.
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 100 }]),
    PrismaModule,
    StorageModule,
    AuthModule,
    UsersModule,
    TasksModule,
    ChecklistModule,
    EvidenceModule,
    LpjModule,
    AuditModule,
    NotificationsModule,
    TravelModule,
    SearchModule,
    DashboardModule,
  ],
  providers: [
    // Urutan guard PENTING: JwtAuthGuard (autentikasi) dijalankan
    // lebih dulu untuk mengisi request.user, baru RolesGuard
    // (otorisasi) mengevaluasi role berdasarkan request.user tsb.
    // ThrottlerGuard ditaruh terakhir - rate limit tetap berlaku baik
    // request diautentikasi maupun tidak (mis. percobaan login bertubi).
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: RolesGuard,
    },
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
