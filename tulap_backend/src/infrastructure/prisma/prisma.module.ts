import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

/**
 * PrismaModule bersifat @Global() agar PrismaService cukup di-import
 * satu kali di AppModule, lalu bisa langsung di-inject ke modul mana
 * pun (auth, users, tasks, dsb) tanpa perlu import berulang-ulang.
 */
@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
