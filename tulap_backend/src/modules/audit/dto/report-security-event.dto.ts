import { IsEnum, IsNumber, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';

/// SecurityEventType
/// ----------------------------------------------------------------------
/// Jenis pelanggaran integritas yang bisa dilaporkan klien mobile.
/// MOCK_LOCATION_BLOCKED: capture ditolak karena Position.isMocked true
/// (Bagian 21 & 30 spesifikasi - anti-fake-GPS). ROOT_DEVICE_BLOCKED:
/// capture ditolak karena RootDetector mendeteksi perangkat rooted.
/// ----------------------------------------------------------------------
export enum SecurityEventType {
  MOCK_LOCATION_BLOCKED = 'MOCK_LOCATION_BLOCKED',
  ROOT_DEVICE_BLOCKED = 'ROOT_DEVICE_BLOCKED',
}

/// ReportSecurityEventDto
/// ----------------------------------------------------------------------
/// Payload laporan client-side saat GeotagCameraRepositoryImpl memblokir
/// aksi pengambilan bukti (foto/video) karena integritas lokasi/perangkat
/// gagal. Ini BUKAN evidence yang berhasil diambil - tidak ada file yang
/// menyertainya, hanya jejak audit bahwa percobaan telah diblokir, agar
/// admin/verifikator bisa melihat pola percobaan manipulasi pada Bagian
/// 31 Audit Trail.
/// ----------------------------------------------------------------------
export class ReportSecurityEventDto {
  @IsEnum(SecurityEventType)
  eventType: SecurityEventType;

  @IsUUID()
  taskId: string;

  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @IsNumber()
  @Min(0)
  accuracyMeters: number;

  @IsString()
  @IsOptional()
  deviceInfo?: string;
}
