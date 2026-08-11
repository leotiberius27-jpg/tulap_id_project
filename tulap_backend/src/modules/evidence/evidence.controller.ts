import {
  BadRequestException,
  Body,
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { RoleName } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { UploadPhotoDto } from './dto/upload-photo.dto';
import { UploadReceiptDto } from './dto/upload-receipt.dto';
import { EvidenceService } from './evidence.service';

// Batas ukuran file - foto & nota di mobile SUDAH dikompresi ke ~300KB
// sebelum dikirim (lihat ImageCompressor di mobile), 5MB adalah batas
// aman dengan margin besar untuk kasus kompresi gagal/dilewati.
const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024;
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/jpg', 'image/png'];

/// EvidenceController
/// ----------------------------------------------------------------------
/// HANYA bisa diakses oleh PEGAWAI - endpoint ini adalah tujuan upload
/// dari Sync Queue mobile (GeotagCameraEngine & OCR Receipt Scanner).
/// Verifikator/Admin TIDAK mengunggah bukti lewat endpoint ini, mereka
/// hanya membaca & memverifikasi lewat modul verification (menyusul).
/// ----------------------------------------------------------------------
@Controller('evidence')
export class EvidenceController {
  constructor(private readonly evidenceService: EvidenceService) {}

  @Roles(RoleName.PEGAWAI)
  @Post('photo')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: MAX_FILE_SIZE_BYTES } }),
  )
  async uploadPhoto(
    @Body() dto: UploadPhotoDto,
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    this._validateFile(file);
    return this.evidenceService.uploadPhoto(dto, file, actor);
  }

  @Roles(RoleName.PEGAWAI)
  @Post('receipt')
  @UseInterceptors(
    FileInterceptor('file', { limits: { fileSize: MAX_FILE_SIZE_BYTES } }),
  )
  async uploadReceipt(
    @Body() dto: UploadReceiptDto,
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    this._validateFile(file);
    return this.evidenceService.uploadReceipt(dto, file, actor);
  }

  private _validateFile(file: Express.Multer.File | undefined) {
    if (!file) {
      throw new BadRequestException('File bukti wajib disertakan.');
    }
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        'Format file tidak didukung. Gunakan JPG atau PNG.',
      );
    }
  }
}
