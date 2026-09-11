import { IsNotEmpty, IsString } from 'class-validator';

export class UnregisterDeviceTokenDto {
  @IsString()
  @IsNotEmpty({ message: 'token wajib diisi.' })
  token: string;
}
