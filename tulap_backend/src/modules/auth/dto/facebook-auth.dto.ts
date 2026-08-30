import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class FacebookAuthDto {
  @IsString()
  @IsNotEmpty({ message: 'accessToken wajib diisi.' })
  accessToken: string;

  @IsString()
  @IsOptional()
  fullName?: string;

  @IsString()
  @IsOptional()
  email?: string;
}
