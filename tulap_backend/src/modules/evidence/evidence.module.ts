import { Module } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { FirestoreSyncModule } from '../../infrastructure/firestore/firestore-sync.module';
import { EvidenceController } from './evidence.controller';
import { EvidenceService } from './evidence.service';

@Module({
  imports: [AuditModule, FirestoreSyncModule],
  controllers: [EvidenceController],
  providers: [EvidenceService],
})
export class EvidenceModule {}
