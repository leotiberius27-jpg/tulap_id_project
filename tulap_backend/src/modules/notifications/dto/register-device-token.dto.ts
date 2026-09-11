import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { DevicePlatform } from '@prisma/client';

export class RegisterDeviceTokenDto {
  @IsString()
  @IsNotEmpty({ message: 'token wajib diisi.' })
  token: string;

  @IsOptional()
  @IsEnum(DevicePlatform)
  platform?: DevicePlatform;
}
