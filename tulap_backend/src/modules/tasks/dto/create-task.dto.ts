import { Type } from 'class-transformer';
import {
  IsDateString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  IsUUID,
  Min,
} from 'class-validator';

/// CreateTaskDto
/// ----------------------------------------------------------------------
/// Dipakai Admin/Super Admin saat membuat penugasan baru (Bagian 14
/// dokumen spesifikasi: "Admin dapat Buat tugas, Pilih petugas,
/// Tentukan lokasi, Jadwal, Deadline..."). `taskCode` (nomor surat
/// tugas) DIBUAT OTOMATIS oleh server, bukan diinput manual - mencegah
/// duplikasi/kesalahan format nomor surat antar admin.
/// ----------------------------------------------------------------------
export class CreateTaskDto {
  @IsString()
  @IsNotEmpty({ message: 'Nama tugas wajib diisi.' })
  taskName: string;

  @IsString()
  @IsNotEmpty({ message: 'Lokasi/destinasi tugas wajib diisi.' })
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

  /// Pegawai yang ditugaskan ke lapangan - WAJIB sudah terdaftar
  /// sebagai user aktif dengan role PEGAWAI (divalidasi di service).
  @IsUUID()
  @IsNotEmpty({ message: 'Petugas yang ditugaskan wajib dipilih.' })
  assigneeId: string;
}
