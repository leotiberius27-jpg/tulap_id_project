import { IsNotEmpty, IsString } from 'class-validator';

export class FirebaseAuthDto {
  @IsString()
  @IsNotEmpty({ message: 'idToken wajib diisi.' })
  idToken: string;
}
