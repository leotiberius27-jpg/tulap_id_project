import { IsNotEmpty, IsNumber, IsOptional, IsString, IsUUID } from 'class-validator';
import { Type } from 'class-transformer';

export class UploadReportDto {
  @IsUUID()
  @IsOptional()
  id?: string;

  @IsUUID()
  @IsNotEmpty()
  taskId: string;

  @IsString()
  @IsNotEmpty()
  reportCode: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsOptional()
  reportType?: string;

  @IsString()
  @IsOptional()
  templateId?: string;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  templateVersion?: number;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  versionNumber?: number;

  @IsString()
  @IsNotEmpty()
  reportSha256: string;

  @IsString()
  @IsOptional()
  summary?: string;

  @IsString()
  @IsOptional()
  narrative?: string;

  @IsString()
  @IsNotEmpty()
  contentSnapshotJson: string;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  totalExpense?: number;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  evidenceCount?: number;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  receiptCount?: number;
}
