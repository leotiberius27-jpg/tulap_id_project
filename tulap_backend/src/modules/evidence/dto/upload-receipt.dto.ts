import { Type } from 'class-transformer';
import {
  IsISO8601,
  IsIn,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

const VALID_CATEGORIES = [
  'bbm',
  'tol',
  'penginapan',
  'retail',
  'konsumsi',
  'transportasiLain',
  'lainnya',
];

/// UploadReceiptDto
/// ----------------------------------------------------------------------
/// Selaras dengan payload dari ExpenseNoteModel.toUploadPayload() di
/// mobile. Kategori dikirim sebagai string camelCase dari mobile,
/// dipetakan ke enum Prisma ExpenseCategory di EvidenceService.
/// ----------------------------------------------------------------------
export class UploadReceiptDto {
  @IsUUID()
  @IsNotEmpty()
  taskId: string;

  @IsString()
  @IsNotEmpty()
  vendorName: string;

  @IsISO8601()
  @IsNotEmpty()
  transactionDate: string;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  totalAmount: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  taxAmount?: number;

  @IsString()
  @IsOptional()
  receiptNumber?: string;

  @IsIn(VALID_CATEGORIES)
  category: string;

  @IsString()
  @IsOptional()
  ocrRawText?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  ocrConfidence?: number;
}
