import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
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

const MAX_FILE_SIZE_BYTES = 100 * 1024 * 1024; // 100MB max (mendukung rekaman video lapangan)
const ALLOWED_MIME_TYPES = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'video/mp4',
  'video/quicktime',
];

/// EvidenceController
/// ----------------------------------------------------------------------
/// Endpoint manajemen dan verifikasi bukti digital kegiatan lapangan.
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
    FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }),
  )
  async uploadReceipt(
    @Body() dto: UploadReceiptDto,
    @UploadedFile() file: Express.Multer.File | undefined,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    if (file) {
      this._validateReceiptFile(file);
    }
    return this.evidenceService.uploadReceipt(dto, file, actor);
  }

  @Get('receipt/:id')
  async getReceipt(
    @Param('id') id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.evidenceService.getEvidenceReceipt(id, actor);
  }

  @Delete('receipt/:id')
  async deleteReceipt(
    @Param('id') id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.evidenceService.deleteEvidenceReceipt(id, actor);
  }

  @Get('photo/:id')
  async getPhoto(
    @Param('id') id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.evidenceService.getEvidencePhoto(id, actor);
  }

  @Get('photo/:id/verify')
  async verifyPhoto(
    @Param('id') id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.evidenceService.verifyEvidencePhoto(id, actor);
  }

  @Delete('photo/:id')
  async deletePhoto(
    @Param('id') id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.evidenceService.deleteEvidencePhoto(id, actor);
  }

  private _validateFile(file: Express.Multer.File | undefined) {
    if (!file) {
      throw new BadRequestException('File bukti wajib disertakan.');
    }
    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        'Format file tidak didukung. Gunakan JPG, PNG, atau MP4.',
      );
    }
  }

  private _validateReceiptFile(file: Express.Multer.File | undefined) {
    if (!file) {
      throw new BadRequestException('File nota wajib disertakan.');
    }
    const allowedReceiptMimes = ['image/jpeg', 'image/jpg', 'image/png'];
    if (!allowedReceiptMimes.includes(file.mimetype)) {
      throw new BadRequestException(
        'Format nota tidak didukung. Gunakan JPG atau PNG.',
      );
    }
  }
}
