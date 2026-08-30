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
  'atk',
  'perlengkapan',
  'lainnya',
  'BBM',
  'TOL',
  'PENGINAPAN',
  'RETAIL',
  'KONSUMSI',
  'TRANSPORTASI_LAIN',
  'LAINNYA',
];

/// UploadReceiptDto
/// ----------------------------------------------------------------------
/// Selaras dengan payload dari ExpenseNoteModel.toUploadPayload() di mobile.
/// ----------------------------------------------------------------------
export class UploadReceiptDto {
  @IsUUID()
  @IsOptional()
  id?: string;

  @IsUUID()
  @IsNotEmpty()
  taskId: string;

  @IsString()
  @IsNotEmpty()
  vendorName: string;

  @IsISO8601()
  @IsNotEmpty()
  transactionDate: string;

  @IsString()
  @IsOptional()
  transactionTime?: string;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  totalAmount: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  subtotal?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  taxAmount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  discountAmount?: number;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  serviceCharge?: number;

  @IsString()
  @IsOptional()
  receiptNumber?: string;

  @IsIn(VALID_CATEGORIES)
  category: string;

  @IsString()
  @IsOptional()
  paymentMethod?: string;

  @IsString()
  @IsOptional()
  notes?: string;

  @IsString()
  @IsOptional()
  ocrRawText?: string;

  @IsNumber()
  @Min(0)
  @IsOptional()
  @Type(() => Number)
  ocrConfidence?: number;

  @IsString()
  @IsOptional()
  originalSha256?: string;

  @IsString()
  @IsOptional()
  processedSha256?: string;

  @IsString()
  @IsOptional()
  source?: string;
}
