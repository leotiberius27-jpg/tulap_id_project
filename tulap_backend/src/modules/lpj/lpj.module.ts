import { Module } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { LpjController } from './lpj.controller';
import { LpjService } from './lpj.service';

@Module({
  imports: [AuditModule, NotificationsModule],
  controllers: [LpjController],
  providers: [LpjService],
})
export class LpjModule {}
