import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';

/// AuditService
/// ----------------------------------------------------------------------
/// Satu-satunya jalur resmi menulis ke Audit_Log (Bagian 31 dokumen
/// spesifikasi: "Setiap perubahan data penting ... dicatat di AuditLog").
/// Append-only - service ini sengaja tidak punya method update/delete.
/// Dipanggil dari service lain (tasks/evidence/lpj/auth), bukan
/// dipanggil langsung dari controller manapun.
/// ----------------------------------------------------------------------
@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  async log(params: {
    actorId?: string | null;
    action: string;
    entity: string;
    entityId: string;
    metadata?: Record<string, unknown>;
  }): Promise<void> {
    await this.prisma.audit_Log.create({
      data: {
        actorId: params.actorId ?? null,
        action: params.action,
        entity: params.entity,
        entityId: params.entityId,
        metadata: params.metadata as Prisma.InputJsonValue | undefined,
      },
    });
  }
}
