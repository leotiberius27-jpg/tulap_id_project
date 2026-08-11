import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './infrastructure/prisma/prisma.module';
import { StorageModule } from './infrastructure/storage/storage.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { TasksModule } from './modules/tasks/tasks.module';
import { ChecklistModule } from './modules/checklist/checklist.module';
import { EvidenceModule } from './modules/evidence/evidence.module';
import { LpjModule } from './modules/lpj/lpj.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RolesGuard } from './common/guards/roles.guard';

@Module({
  imports: [
    // isGlobal: true -> ConfigService bisa langsung di-inject ke modul
    // manapun tanpa perlu import ConfigModule berulang kali.
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    StorageModule,
    AuthModule,
    UsersModule,
    TasksModule,
    ChecklistModule,
    EvidenceModule,
    LpjModule,
  ],
  providers: [
    // Urutan guard PENTING: JwtAuthGuard (autentikasi) dijalankan
    // lebih dulu untuk mengisi request.user, baru RolesGuard
    // (otorisasi) mengevaluasi role berdasarkan request.user tsb.
    {
      provide: APP_GUARD,
      useClass: JwtAuthGuard,
    },
    {
      provide: APP_GUARD,
      useClass: RolesGuard,
    },
  ],
})
export class AppModule {}
