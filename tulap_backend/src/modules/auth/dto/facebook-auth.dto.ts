import { IsNotEmpty, IsString } from 'class-validator';

export class FacebookAuthDto {
  @IsString()
  @IsNotEmpty({ message: 'accessToken wajib diisi.' })
  accessToken: string;
}
