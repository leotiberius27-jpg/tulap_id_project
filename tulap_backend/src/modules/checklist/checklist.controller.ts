import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { ChecklistService } from './checklist.service';
import { CreateChecklistItemsBulkDto } from './dto/create-checklist-item.dto';
import { ToggleChecklistItemDto } from './dto/toggle-checklist-item.dto';

/// Route nested di bawah /tasks/:taskId/checklist - checklist tidak
/// pernah berdiri sendiri tanpa konteks tugas, jadi URL-nya
/// mencerminkan hierarki data yang sebenarnya.
@Controller('tasks/:taskId/checklist')
export class ChecklistController {
  constructor(private readonly checklistService: ChecklistService) {}

  @Get()
  findByTask(
    @Param('taskId') taskId: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.checklistService.findByTask(taskId, actor);
  }

  @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Post()
  createBulk(
    @Param('taskId') taskId: string,
    @Body() dto: CreateChecklistItemsBulkDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.checklistService.createBulk(taskId, dto, actor);
  }

  @Roles(RoleName.PEGAWAI)
  @Patch(':itemId')
  toggleComplete(
    @Param('taskId') taskId: string,
    @Param('itemId') itemId: string,
    @Body() dto: ToggleChecklistItemDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.checklistService.toggleComplete(
      taskId,
      itemId,
      dto.isCompleted,
      actor,
    );
  }
}
