import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { AssistantService } from './assistant.service';
import { AssistantQueryDto } from './dto/assistant-query.dto';
import { AssistantResponseDto } from './dto/assistant-response.dto';

@Controller('assistant')
@UseGuards(JwtAuthGuard)
export class AssistantController {
  constructor(private readonly assistantService: AssistantService) {}

  @Post('query')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  async query(
    @Body() dto: AssistantQueryDto,
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<AssistantResponseDto> {
    return this.assistantService.processQuery(dto, user);
  }
}
