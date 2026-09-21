import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { CreateTaskDto } from './dto/create-task.dto';
import { CreateSelfTaskDto } from './dto/create-self-task.dto';
import { QueryTasksDto } from './dto/query-tasks.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { RevisionNoteDto } from './dto/revision-note.dto';
import { TasksService } from './tasks.service';

@Controller('tasks')
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  /// POST /tasks - hanya ADMIN/SUPER_ADMIN yang membuat penugasan,
  /// sesuai Bagian 14 spesifikasi.
  @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Post()
  create(@Body() dto: CreateTaskDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.tasksService.create(dto, actor);
  }

  /// POST /tasks/self - PEGAWAI membuat kegiatan lapangan MANDIRI dari
  /// mobile, tanpa menunggu penugasan Admin (fitur "Buat Kegiatan
  /// Lapangan"). Berbeda dari POST /tasks di atas: tidak butuh
  /// `assigneeId` (otomatis diri sendiri) dan tidak dibatasi ke role
  /// ADMIN/SUPER_ADMIN.
  @Roles(RoleName.PEGAWAI)
  @Post('self')
  createSelf(
    @Body() dto: CreateSelfTaskDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.tasksService.createSelf(dto, actor);
  }

  /// GET /tasks - TIDAK dibatasi @Roles() tambahan (semua role login
  /// boleh akses), karena PEGAWAI perlu melihat daftar tugasnya
  /// sendiri di Beranda/Riwayat mobile. Pembatasan "hanya tugas
  /// miliknya" untuk PEGAWAI diterapkan di dalam TasksService.findAll.
  @Get()
  findAll(@Query() query: QueryTasksDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.tasksService.findAll(query, actor);
  }

  @Get(':id')
  findOne(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.tasksService.findOne(id, actor);
  }

  /// GET /tasks/:id/evidence - foto & nota tugas ini, dipakai
  /// Verification Workspace Web Dashboard. Akses sama seperti
  /// GET /tasks/:id (tidak dibatasi @Roles() tambahan - PEGAWAI boleh
  /// lihat evidence tugasnya sendiri, pembatasan diterapkan di service).
  @Get(':id/evidence')
  getEvidence(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.tasksService.getEvidence(id, actor);
  }

  @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateTaskDto) {
    return this.tasksService.update(id, dto);
  }

  // ============================================================
  // TRANSISI STATUS - masing-masing endpoint sempit & eksplisit,
  // BUKAN satu endpoint generik "PATCH /tasks/:id/status" yang
  // menerima status apa pun - supaya izin akses per transisi bisa
  // dibedakan lewat @Roles() per endpoint.
  // ============================================================

  @Roles(RoleName.PEGAWAI)
  @Post(':id/start')
  startTask(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.tasksService.startTask(id, actor);
  }

  @Roles(RoleName.PEGAWAI)
  @Post(':id/submit')
  submitForVerification(
    @Param('id') id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.tasksService.submitForVerification(id, actor);
  }

  @Roles(RoleName.PEGAWAI)
  @Post(':id/resubmit')
  resubmitAfterRevision(
    @Param('id') id: string,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.tasksService.resubmitAfterRevision(id, actor);
  }

  @Roles(RoleName.VERIFIKATOR, RoleName.SUPER_ADMIN)
  @Post(':id/approve')
  approve(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.tasksService.approve(id, actor);
  }

  @Roles(RoleName.VERIFIKATOR, RoleName.SUPER_ADMIN)
  @Post(':id/request-revision')
  requestRevision(
    @Param('id') id: string,
    @Body() dto: RevisionNoteDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.tasksService.requestRevision(id, dto, actor);
  }

  @Roles(RoleName.VERIFIKATOR, RoleName.SUPER_ADMIN)
  @Post(':id/reject')
  reject(
    @Param('id') id: string,
    @Body() dto: RevisionNoteDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.tasksService.reject(id, dto, actor);
  }

  // CATATAN: dokumen spesifikasi produk (Bagian 6) menyebut role
  // BENDAHARA & PIMPINAN, namun skema Prisma saat ini baru mendukung
  // 4 role (PEGAWAI, VERIFIKATOR, ADMIN, SUPER_ADMIN). Endpoint ini
  // sementara memakai ADMIN untuk merepresentasikan wewenang finalisasi
  // - tambahkan BENDAHARA ke enum RoleName di schema.prisma lebih dulu
  // (lalu migrate) sebelum mengaktifkan role tsb secara terpisah di sini.
  @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Post(':id/complete')
  complete(@Param('id') id: string, @CurrentUser() actor: AuthenticatedUser) {
    return this.tasksService.complete(id, actor);
  }
}
