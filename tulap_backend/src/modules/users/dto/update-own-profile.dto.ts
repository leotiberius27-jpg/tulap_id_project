import { IsOptional, IsString } from 'class-validator';

/// UpdateOwnProfileDto
/// ----------------------------------------------------------------------
/// Dipakai HANYA oleh `PATCH /users/me` - berbeda dari UpdateUserDto
/// (dipakai Admin lewat `PATCH /users/:id`) karena SENGAJA tidak
/// menyertakan `roleName`/`isActive`/`unitKerja`: pengguna biasa tidak
/// boleh mengubah role atau status aktifnya sendiri lewat endpoint ini.
/// ----------------------------------------------------------------------
export class UpdateOwnProfileDto {
  @IsString()
  @IsOptional()
  fullName?: string;

  @IsString()
  @IsOptional()
  phoneNumber?: string;

  @IsString()
  @IsOptional()
  instansiName?: string;

  @IsString()
  @IsOptional()
  nip?: string;
}
