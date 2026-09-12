import { Module } from '@nestjs/common';
import { ChecklistModule } from '../checklist/checklist.module';
import { AuditModule } from '../audit/audit.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';
import { FirestoreSyncModule } from '../../infrastructure/firestore/firestore-sync.module';
import { TasksController } from './tasks.controller';
import { TasksService } from './tasks.service';

@Module({
  imports: [
    ChecklistModule,
    AuditModule,
    NotificationsModule,
    SubscriptionsModule,
    FirestoreSyncModule,
  ],
  controllers: [TasksController],
  providers: [TasksService],
  exports: [TasksService],
})
export class TasksModule {}
