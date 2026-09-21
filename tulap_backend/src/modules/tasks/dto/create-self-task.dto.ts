import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';

export class SelfTaskChecklistItemDto {
  /// ID lokal (UUID) dari mobile - dipertahankan agar item checklist yang
  /// sudah dicentang offline sebelum tersinkron tidak berubah identitas.
  @IsUUID()
  @IsOptional()
  id?: string;

  @IsString()
  @IsNotEmpty()
  label: string;

  @IsInt()
  @Min(1)
  order: number;

  @IsBoolean()
  @IsOptional()
  isMandatory?: boolean;

  @IsBoolean()
  @IsOptional()
  isCompleted?: boolean;
}

/// CreateSelfTaskDto
/// ----------------------------------------------------------------------
/// Dipakai PEGAWAI saat membuat kegiatan lapangan MANDIRI dari mobile
/// (tanpa menunggu penugasan Admin) - lihat CreateActivity use case di
/// mobile. `id`/`taskCode` opsional & berasal dari mobile (dibuat saat
/// offline) supaya proses sinkronisasi ulang (retry outbox) bersifat
/// idempoten - tidak membuat duplikat tugas jika request sebelumnya
/// sebenarnya sudah berhasil namun response-nya gagal diterima device.
/// ----------------------------------------------------------------------
export class CreateSelfTaskDto {
  @IsUUID()
  @IsOptional()
  id?: string;

  @IsString()
  @IsOptional()
  taskCode?: string;

  @IsString()
  @IsNotEmpty({ message: 'Nama kegiatan wajib diisi.' })
  taskName: string;

  @IsString()
  @IsNotEmpty({ message: 'Lokasi/destinasi kegiatan wajib diisi.' })
  destination: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsDateString()
  @IsNotEmpty()
  startDate: string;

  @IsDateString()
  @IsNotEmpty()
  endDate: string;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  budgetAmount: number;

  @IsArray()
  @ArrayMinSize(1, { message: 'Minimal sertakan 1 butir checklist lapangan.' })
  @ValidateNested({ each: true })
  @Type(() => SelfTaskChecklistItemDto)
  checklistItems: SelfTaskChecklistItemDto[];
}
