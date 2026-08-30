import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { Response } from 'express';
import { RoleName } from '@prisma/client';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { GenerateLpjDto } from './dto/generate-lpj.dto';
import { UploadReportDto } from './dto/upload-report.dto';
import { LpjService } from './lpj.service';

@Controller('lpj')
export class LpjController {
  constructor(private readonly lpjService: LpjService) {}

  @Roles(RoleName.VERIFIKATOR, RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Post('generate')
  async generate(
    @Body() dto: GenerateLpjDto,
    @CurrentUser() actor: AuthenticatedUser,
    @Res() res: Response,
  ) {
    const { buffer, fileName } = await this.lpjService.generate(dto, actor);

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="${fileName}"`,
      'Content-Length': buffer.length,
    });
    res.send(buffer);
  }

  @Post('report/upload')
  @UseInterceptors(FileInterceptor('file'))
  async uploadReport(
    @Body() dto: UploadReportDto,
    @UploadedFile() file: Express.Multer.File | undefined,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.lpjService.uploadReport(dto, file, actor);
  }

  @Get('report/task/:taskId')
  async getTaskReports(
    @Param('taskId', ParseUUIDPipe) taskId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.lpjService.getTaskReports(taskId, actor);
  }

  @Get('report/:id')
  async getReportById(
    @Param('id', ParseUUIDPipe) reportId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.lpjService.getReportById(reportId, actor);
  }

  @Delete('report/:id')
  async deleteReport(
    @Param('id', ParseUUIDPipe) reportId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.lpjService.deleteReport(reportId, actor);
  }
}

