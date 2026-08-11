import { Type } from 'class-transformer';
import {
  IsDateString,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

/// UpdateTaskDto tidak menyertakan `status` - perubahan status punya
/// aturan transisi & pemicu berbeda (mis. status PENDING_VERIFICATION
/// dipicu pegawai submit, VERIFIED dipicu verifikator approve), jadi
/// ditangani lewat method service terpisah (submitForVerification,
/// approveTask, requestRevision), bukan lewat update generik ini.
export class UpdateTaskDto {
  @IsString()
  @IsOptional()
  taskName?: string;

  @IsString()
  @IsOptional()
  destination?: string;

  @IsString()
  @IsOptional()
  description?: string;

  @IsDateString()
  @IsOptional()
  startDate?: string;

  @IsDateString()
  @IsOptional()
  endDate?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  budgetAmount?: number;

  @IsUUID()
  @IsOptional()
  assigneeId?: string;
}
