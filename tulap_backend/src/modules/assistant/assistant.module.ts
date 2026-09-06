import { Module } from '@nestjs/common';
import { PrismaModule } from '../../infrastructure/prisma/prisma.module';
import { SearchModule } from '../search/search.module';
import { TasksModule } from '../tasks/tasks.module';
import { TravelModule } from '../travel/travel.module';
import { LpjModule } from '../lpj/lpj.module';
import { EvidenceModule } from '../evidence/evidence.module';
import { AuditModule } from '../audit/audit.module';
import { AssistantController } from './assistant.controller';
import { AssistantService } from './assistant.service';
import { AssistantLanguageModel } from './services/assistant-language-model.interface';
import { DefaultAssistantLanguageModelService } from './services/default-assistant-language-model.service';

@Module({
  imports: [
    PrismaModule,
    SearchModule,
    TasksModule,
    TravelModule,
    LpjModule,
    EvidenceModule,
    AuditModule,
  ],
  controllers: [AssistantController],
  providers: [
    AssistantService,
    DefaultAssistantLanguageModelService,
    {
      provide: AssistantLanguageModel,
      useClass: DefaultAssistantLanguageModelService,
    },
  ],
  exports: [AssistantService],
})
export class AssistantModule {}
