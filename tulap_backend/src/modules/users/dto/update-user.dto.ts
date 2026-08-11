import {
  IsBoolean,
  IsEnum,
  IsOptional,
  IsString,
} from 'class-validator';
import { RoleName } from '@prisma/client';

/// UpdateUserDto tidak menyertakan `email` maupun `password` - dua
/// field sensitif itu diberi endpoint TERPISAH (lihat users.controller.ts)
/// agar perubahan email/password bisa punya aturan keamanan sendiri
/// (mis. verifikasi ulang, notifikasi ke user) tanpa tercampur dengan
/// update data profil biasa.
export class UpdateUserDto {
  @IsString()
  @IsOptional()
  nip?: string;

  @IsString()
  @IsOptional()
  fullName?: string;

  @IsString()
  @IsOptional()
  phoneNumber?: string;

  @IsString()
  @IsOptional()
  instansiName?: string;

  @IsString()
  @IsOptional()
  unitKerja?: string;

  @IsEnum(RoleName)
  @IsOptional()
  roleName?: RoleName;

  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
