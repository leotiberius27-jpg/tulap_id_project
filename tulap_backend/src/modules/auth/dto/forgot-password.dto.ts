import { IsEmail, IsNotEmpty } from 'class-validator';

export class ForgotPasswordDto {
  @IsEmail({}, { message: 'Format email tidak valid.' })
  @IsNotEmpty()
  email: string;
}
