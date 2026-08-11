import {
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';
import { RoleName } from '@prisma/client';

/**
 * DTO untuk pendaftaran user baru.
 * Endpoint ini HANYA boleh diakses oleh ADMIN/SUPER_ADMIN (lihat
 * penerapan @Roles() di auth.controller.ts) — pegawai tidak bisa
 * mendaftarkan diri sendiri secara mandiri (self-registration ditutup
 * demi kontrol akses instansi pemerintah).
 */
export class RegisterDto {
  @IsString()
  @IsOptional()
  nip?: string;

  @IsString()
  @IsNotEmpty({ message: 'Nama lengkap wajib diisi.' })
  fullName: string;

  @IsEmail({}, { message: 'Format email tidak valid.' })
  @IsNotEmpty()
  email: string;

  @IsString()
  @MinLength(8, { message: 'Password minimal 8 karakter.' })
  password: string;

  @IsString()
  @IsOptional()
  phoneNumber?: string;

  @IsString()
  @IsOptional()
  instansiName?: string;

  @IsString()
  @IsOptional()
  unitKerja?: string;

  @IsEnum(RoleName, { message: 'Role tidak valid.' })
  @IsNotEmpty({ message: 'Role wajib ditentukan.' })
  roleName: RoleName;
}
