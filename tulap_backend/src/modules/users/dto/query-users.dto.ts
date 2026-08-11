import { Type } from 'class-transformer';
import { IsEnum, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { RoleName } from '@prisma/client';

export class QueryUsersDto {
  @IsInt()
  @Min(1)
  @IsOptional()
  @Type(() => Number)
  page?: number = 1;

  @IsInt()
  @Min(1)
  @Max(100)
  @IsOptional()
  @Type(() => Number)
  pageSize?: number = 20;

  /// Pencarian bebas di nama, email, atau NIP - dipakai fitur pencarian
  /// arsip/pegawai (Bagian 9 dokumen requirement awal).
  @IsString()
  @IsOptional()
  search?: string;

  @IsEnum(RoleName)
  @IsOptional()
  roleName?: RoleName;

  @IsString()
  @IsOptional()
  instansiName?: string;
}
