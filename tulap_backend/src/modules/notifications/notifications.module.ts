import { Module } from '@nestjs/common';
import { PushNotificationModule } from '../../infrastructure/push/push-notification.module';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

@Module({
  imports: [PushNotificationModule],
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
