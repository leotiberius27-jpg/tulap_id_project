import { IsEmail, IsNotEmpty, IsString, Length, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @IsEmail({}, { message: 'Format email tidak valid.' })
  @IsNotEmpty()
  email: string;

  @IsString()
  @Length(6, 6, { message: 'Kode reset harus 6 digit.' })
  code: string;

  @IsString()
  @MinLength(8, { message: 'Password minimal 8 karakter.' })
  newPassword: string;
}
