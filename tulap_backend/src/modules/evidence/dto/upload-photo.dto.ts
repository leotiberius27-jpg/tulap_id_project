import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsISO8601,
  IsLatitude,
  IsLongitude,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

/// UploadPhotoDto
/// ----------------------------------------------------------------------
/// Data non-file dari `multipart/form-data` yang dikirim
/// GeotagCameraSyncRemoteDataSource di mobile (lihat toUploadPayload()
/// di GeotagPhotoModel). File gambar sendiri ditangani terpisah lewat
/// FileInterceptor di controller, bukan bagian dari DTO ini.
/// ----------------------------------------------------------------------
export class UploadPhotoDto {
  @IsUUID()
  @IsNotEmpty()
  taskId: string;

  @IsLatitude()
  @Type(() => Number)
  latitude: number;

  @IsLongitude()
  @Type(() => Number)
  longitude: number;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  gpsAccuracyMeters: number;

  /// Timestamp dari mobile (fallback offline-first, jam device) -
  /// TIDAK dipakai sebagai timestamp final. Server SELALU mencatat
  /// waktu penerimaan request-nya sendiri sebagai serverTimestamp
  /// otoritatif (lihat EvidenceService.uploadPhoto) - field ini hanya
  /// disimpan sebagai referensi/audit trail kapan device mengklaim
  /// foto diambil.
  @IsISO8601()
  @IsNotEmpty()
  serverTimestamp: string;

  @IsString()
  @IsNotEmpty()
  integrityHash: string;

  @IsBoolean()
  @Type(() => Boolean)
  isMockLocationDetected: boolean;

  @IsBoolean()
  @Type(() => Boolean)
  isRootedDeviceDetected: boolean;

  @IsString()
  @IsOptional()
  address?: string;

  @IsString()
  @IsOptional()
  caption?: string;

  @IsString()
  @IsOptional()
  id?: string;

  @IsString()
  @IsOptional()
  mediaType?: string;

  @IsNumber()
  @IsOptional()
  @Type(() => Number)
  durationSeconds?: number;

  @IsString()
  @IsOptional()
  originalHash?: string;

  @IsString()
  @IsOptional()
  finalHash?: string;

  @IsString()
  @IsOptional()
  shortEvidenceId?: string;

  @IsISO8601()
  @IsOptional()
  deviceTimestamp?: string;
}

