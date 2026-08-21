import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class AppleAuthDto {
  @IsString()
  @IsNotEmpty({ message: 'identityToken wajib diisi.' })
  identityToken: string;

  // Apple hanya mengirim nama lengkap user ke CLIENT (bukan di dalam
  // token) dan HANYA pada login pertama kali - mobile meneruskannya di
  // sini supaya bisa dipakai mengisi `fullName` saat akun baru dibuat.
  @IsString()
  @IsOptional()
  fullName?: string;
}
