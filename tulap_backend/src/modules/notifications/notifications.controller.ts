import { Body, Controller, Delete, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { QueryNotificationsDto } from './dto/query-notifications.dto';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UnregisterDeviceTokenDto } from './dto/unregister-device-token.dto';
import { NotificationsService } from './notifications.service';

/// NotificationsController
/// ----------------------------------------------------------------------
/// Tidak ada @Roles() tambahan di controller ini - SEMUA role login
/// (PEGAWAI/VERIFIKATOR/ADMIN/SUPER_ADMIN) boleh membaca & menandai
/// notifikasi MILIKNYA SENDIRI. Isolasi antar-user diterapkan di
/// NotificationsService (filter `userId: actor.id`), bukan lewat RBAC.
/// ----------------------------------------------------------------------
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  findAll(@Query() query: QueryNotificationsDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.notificationsService.findAllForUser(actor, query.page ?? 1, query.pageSize ?? 20);
  }

  @Patch(':id/read')
  markRead(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.notificationsService.markRead(id, actor);
  }

  @Patch('read-all')
  markAllRead(@CurrentUser() actor: AuthenticatedUser) {
    return this.notificationsService.markAllRead(actor);
  }

  @Post('device-token')
  registerDeviceToken(
    @Body() dto: RegisterDeviceTokenDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.notificationsService.registerDeviceToken(dto, actor);
  }

  @Delete('device-token')
  unregisterDeviceToken(
    @Body() dto: UnregisterDeviceTokenDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.notificationsService.unregisterDeviceToken(dto.token, actor);
  }
}
