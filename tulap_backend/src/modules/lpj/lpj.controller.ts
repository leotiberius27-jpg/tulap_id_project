import { Body, Controller, Post, Res } from '@nestjs/common';
import { Response } from 'express';
import { RoleName } from '@prisma/client';
import { Roles } from '../../common/decorators/roles.decorator';
import { GenerateLpjDto } from './dto/generate-lpj.dto';
import { LpjService } from './lpj.service';

/// LpjController
/// ----------------------------------------------------------------------
/// `POST /lpj/generate` sesuai Bagian 29 (API Domain Recommendation).
/// Hanya Verifikator/Admin/Super Admin yang boleh generate LPJ, sesuai
/// Permission Model Bagian 26 (tanggung jawab BENDAHARA - termasuk
/// generate LPJ - sudah digabung ke VERIFIKATOR).
/// ----------------------------------------------------------------------
@Controller('lpj')
export class LpjController {
  constructor(private readonly lpjService: LpjService) {}

  @Roles(RoleName.VERIFIKATOR, RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Post('generate')
  async generate(@Body() dto: GenerateLpjDto, @Res() res: Response) {
    const { buffer, fileName } = await this.lpjService.generate(dto);

    res.set({
      'Content-Type': 'application/pdf',
      'Content-Disposition': `attachment; filename="${fileName}"`,
      'Content-Length': buffer.length,
    });
    res.send(buffer);
  }
}
