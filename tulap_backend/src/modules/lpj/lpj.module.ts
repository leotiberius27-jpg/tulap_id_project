import { Module } from '@nestjs/common';
import { LpjController } from './lpj.controller';
import { LpjService } from './lpj.service';

@Module({
  controllers: [LpjController],
  providers: [LpjService],
})
export class LpjModule {}
