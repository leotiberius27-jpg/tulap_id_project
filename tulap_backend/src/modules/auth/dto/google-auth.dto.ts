import { IsNotEmpty, IsString } from 'class-validator';

export class GoogleAuthDto {
  @IsString()
  @IsNotEmpty({ message: 'idToken wajib diisi.' })
  idToken: string;
}
