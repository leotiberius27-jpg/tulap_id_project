import { IsString, MinLength } from 'class-validator';

/// Dipakai oleh POST /tasks/:id/request-revision dan POST /tasks/:id/reject
/// - Verifikator WAJIB menuliskan alasan spesifik (Bagian 22: "Nota BBM -
/// Nominal kurang jelas"), bukan sekadar mengubah status tanpa penjelasan.
export class RevisionNoteDto {
  @IsString()
  @MinLength(3, { message: 'Catatan revisi terlalu pendek, jelaskan apa yang perlu diperbaiki.' })
  note: string;
}
