import { Module } from '@nestjs/common';
import { FirestoreSyncService } from './firestore-sync.service';

@Module({
  providers: [FirestoreSyncService],
  exports: [FirestoreSyncService],
})
export class FirestoreSyncModule {}
