import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';

/**
 * DTO untuk validasi input saat proses login.
 * class-validator otomatis menolak request dengan format tidak sesuai
 * sebelum masuk ke business logic (fail-fast validation).
 */
export class LoginDto {
  @IsEmail({}, { message: 'Format email tidak valid.' })
  @IsNotEmpty({ message: 'Email wajib diisi.' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'Password wajib diisi.' })
  @MinLength(8, { message: 'Password minimal 8 karakter.' })
  password: string;
}
