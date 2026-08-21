import { Controller, Get, Query } from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { Roles } from '../../common/decorators/roles.decorator';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { QueryAuditLogsDto } from './dto/query-audit-logs.dto';

/// GET /audit-logs (Bagian 29 - API Domain Recommendation). Hanya
/// ADMIN/SUPER_ADMIN yang boleh membaca jejak audit lintas sistem -
/// selaras dengan Permission Model (Bagian 26) yang tidak memberi
/// PEGAWAI/VERIFIKATOR akses ke log tindakan pihak lain.
@Controller('audit-logs')
export class AuditController {
  constructor(private readonly prisma: PrismaService) {}

  @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Get()
  async findAll(@Query() query: QueryAuditLogsDto) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 50;

    const where: Record<string, unknown> = {};
    if (query.entity) where.entity = query.entity;
    if (query.entityId) where.entityId = query.entityId;
    if (query.actorId) where.actorId = query.actorId;

    const [items, total] = await Promise.all([
      this.prisma.audit_Log.findMany({
        where,
        skip: (page - 1) * pageSize,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
        include: { actor: { select: { id: true, fullName: true, email: true } } },
      }),
      this.prisma.audit_Log.count({ where }),
    ]);

    return {
      items,
      meta: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) },
    };
  }
}
