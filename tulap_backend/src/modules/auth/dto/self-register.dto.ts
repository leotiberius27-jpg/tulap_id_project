import { IsEmail, IsNotEmpty, IsOptional, IsString, MinLength } from 'class-validator';

/**
 * DTO untuk pendaftaran mandiri (self-registration) dari mobile app -
 * berbeda dari RegisterDto (dipakai Admin lewat POST /auth/register):
 * TIDAK ada field `roleName` - akun hasil self-registration SELALU
 * dibuat dengan role PEGAWAI (lihat AuthService.selfRegister), tidak
 * pernah bisa memilih role sendiri.
 */
export class SelfRegisterDto {
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
  @IsNotEmpty({ message: 'Nama instansi wajib diisi.' })
  instansiName: string;

  @IsString()
  @IsOptional()
  phoneNumber?: string;
}
