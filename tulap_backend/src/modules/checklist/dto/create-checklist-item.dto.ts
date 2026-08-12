import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';

export class CreateChecklistItemDto {
  @IsString()
  @IsNotEmpty({ message: 'Label checklist wajib diisi.' })
  label: string;

  @IsInt()
  @Min(0)
  order: number;

  @IsBoolean()
  @IsOptional()
  isMandatory?: boolean = true;
}

/// DTO untuk membuat banyak item checklist sekaligus - dipakai saat
/// Admin membuat penugasan baru dan langsung mendefinisikan seluruh
/// checklist-nya dalam satu request (Bagian 14 spesifikasi: "Tentukan
/// checklist" adalah bagian dari form pembuatan tugas).
export class CreateChecklistItemsBulkDto {
  @IsArray()
  @ArrayMinSize(1, { message: 'Minimal satu item checklist diperlukan.' })
  @ValidateNested({ each: true })
  @Type(() => CreateChecklistItemDto)
  items: CreateChecklistItemDto[];
}
