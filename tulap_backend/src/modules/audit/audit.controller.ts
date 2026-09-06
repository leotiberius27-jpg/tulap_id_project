import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuditService } from './audit.service';
import { QueryAuditLogsDto } from './dto/query-audit-logs.dto';
import { ReportSecurityEventDto } from './dto/report-security-event.dto';

/// GET /audit-logs (Bagian 29 - API Domain Recommendation). Hanya
/// ADMIN/SUPER_ADMIN yang boleh membaca jejak audit lintas sistem -
/// selaras dengan Permission Model (Bagian 26) yang tidak memberi
/// PEGAWAI/VERIFIKATOR akses ke log tindakan pihak lain.
@Controller('audit-logs')
export class AuditController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
  ) {}

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

  /// POST /audit-logs/security-event - endpoint TANPA @Roles: setiap
  /// PEGAWAI yang capture-nya diblokir client-side (mock location / root
  /// device, lihat GeotagCameraRepositoryImpl di mobile) harus bisa
  /// melaporkan percobaan ini sendiri, bukan hanya ADMIN. Menulis lewat
  /// AuditService.log() (satu-satunya jalur resmi ke Audit_Log, Bagian
  /// 31) - bukan tabel/endpoint baru, supaya percobaan manipulasi lokasi
  /// tetap terlihat di jejak audit yang sama dan dapat difilter admin
  /// lewat GET /audit-logs?entity=SECURITY di atas.
  @Post('security-event')
  async reportSecurityEvent(
    @Body() dto: ReportSecurityEventDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    await this.auditService.log({
      actorId: actor.id,
      action: dto.eventType,
      entity: 'SECURITY',
      entityId: dto.taskId,
      metadata: {
        latitude: dto.latitude,
        longitude: dto.longitude,
        accuracyMeters: dto.accuracyMeters,
        deviceInfo: dto.deviceInfo,
      },
    });
    return { received: true };
  }
}
