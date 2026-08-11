import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService], // Diekspor agar modul lain (mis. tasks saat assign pegawai) bisa memakainya
})
export class UsersModule {}
