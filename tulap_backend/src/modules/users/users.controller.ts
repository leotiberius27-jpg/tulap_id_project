import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { QueryUsersDto } from './dto/query-users.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersService } from './users.service';

/// Pembuatan user baru (Create) SENGAJA TIDAK ada di controller ini -
/// endpoint tsb sudah ada di AuthController (`POST /auth/register`),
/// karena proses pembuatan user terikat erat dengan hashing password
/// & pemilihan role awal. Controller ini fokus pada Read/Update/
/// Deactivate agar tidak ada dua jalur berbeda untuk membuat user.
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /// GET /users - daftar pegawai, hanya ADMIN/VERIFIKATOR/SUPER_ADMIN
  /// yang perlu melihat daftar lengkap pegawai lintas instansi.
  @Roles(RoleName.ADMIN, RoleName.VERIFIKATOR, RoleName.SUPER_ADMIN)
  @Get()
  findAll(@Query() query: QueryUsersDto) {
    return this.usersService.findAll(query);
  }

  /// GET /users/:id - detail satu pegawai. Tidak dibatasi @Roles()
  /// tambahan (selain harus login) karena PEGAWAI biasa pun berhak
  /// melihat profilnya sendiri lewat endpoint ini (mis. dari layar Akun
  /// di mobile) - kontrol lebih detail (hanya boleh lihat diri sendiri
  /// vs semua orang) diterapkan di query 'GET /auth/profile' untuk diri
  /// sendiri, endpoint ini dipakai Admin untuk lihat pegawai lain.
  @Roles(RoleName.ADMIN, RoleName.VERIFIKATOR, RoleName.SUPER_ADMIN)
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  /// PATCH /users/:id - update profil & role. Aturan "tidak bisa
  /// menaikkan ke SUPER_ADMIN kecuali oleh SUPER_ADMIN" ditegakkan DI
  /// DALAM UsersService (butuh data `actor`, bukan hanya daftar role
  /// statis yang bisa dicek RolesGuard).
  @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateUserDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.usersService.update(id, dto, actor);
  }

  /// DELETE /users/:id - SOFT delete (menonaktifkan), bukan hard
  /// delete. Lihat penjelasan lengkap alasan di UsersService.deactivate.
  @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Delete(':id')
  deactivate(
    @Param('id') id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.usersService.deactivate(id, actor);
  }

  /// POST /users/:id/reactivate - mengaktifkan kembali pegawai yang
  /// sebelumnya dinonaktifkan (mis. salah nonaktifkan, atau pegawai
  /// aktif kembali bertugas).
  @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Post(':id/reactivate')
  reactivate(@Param('id') id: string) {
    return this.usersService.reactivate(id);
  }
}
