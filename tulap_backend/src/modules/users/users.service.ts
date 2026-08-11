import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { RoleName } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { QueryUsersDto } from './dto/query-users.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  /// Daftar pegawai dengan pagination, pencarian, dan filter role/instansi.
  /// Password hash TIDAK PERNAH ikut ter-select, sesuai prinsip data
  /// minimization UU PDP No. 27/2022.
  async findAll(query: QueryUsersDto) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 20;

    const where: any = {};

    if (query.search) {
      where.OR = [
        { fullName: { contains: query.search, mode: 'insensitive' } },
        { email: { contains: query.search, mode: 'insensitive' } },
        { nip: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    if (query.roleName) {
      where.role = { name: query.roleName };
    }

    if (query.instansiName) {
      where.instansiName = { contains: query.instansiName, mode: 'insensitive' };
    }

    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip: (page - 1) * pageSize,
        take: pageSize,
        orderBy: { fullName: 'asc' },
        select: this._safeUserSelect(),
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      items,
      meta: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
    };
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: this._safeUserSelect(),
    });

    if (!user) {
      throw new NotFoundException('Pegawai tidak ditemukan.');
    }

    return user;
  }

  /// Update data profil pegawai. Menegakkan aturan RBAC tambahan yang
  /// TIDAK bisa direpresentasikan oleh RolesGuard biasa: seorang ADMIN
  /// (non-SUPER_ADMIN) TIDAK BOLEH menaikkan role siapa pun menjadi
  /// SUPER_ADMIN - hanya SUPER_ADMIN yang boleh membuat SUPER_ADMIN
  /// baru. Ini mencegah eskalasi privilege oleh Admin instansi biasa.
  async update(id: string, dto: UpdateUserDto, actor: AuthenticatedUser) {
    const targetUser = await this.prisma.user.findUnique({ where: { id } });
    if (!targetUser) {
      throw new NotFoundException('Pegawai tidak ditemukan.');
    }

    if (
      dto.roleName === RoleName.SUPER_ADMIN &&
      actor.role !== RoleName.SUPER_ADMIN
    ) {
      throw new ForbiddenException(
        'Hanya Super Admin yang dapat menetapkan role Super Admin.',
      );
    }

    let roleId: string | undefined;
    if (dto.roleName) {
      const role = await this.prisma.role.findUnique({
        where: { name: dto.roleName },
      });
      if (!role) {
        throw new BadRequestException(`Role '${dto.roleName}' tidak valid.`);
      }
      roleId = role.id;
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data: {
        nip: dto.nip,
        fullName: dto.fullName,
        phoneNumber: dto.phoneNumber,
        instansiName: dto.instansiName,
        unitKerja: dto.unitKerja,
        isActive: dto.isActive,
        roleId,
      },
      select: this._safeUserSelect(),
    });

    return updated;
  }

  /// "Hapus" pegawai TIDAK melakukan hard delete - hanya menonaktifkan
  /// (isActive = false). Ini SENGAJA, karena data historis pegawai
  /// (tugas, foto, nota yang pernah dibuatnya) harus tetap terlacak
  /// untuk kebutuhan audit BPK/Inspektorat, sesuai prinsip Audit Trail
  /// di dokumen spesifikasi. Hard delete akan merusak integritas
  /// referensial data historis tsb.
  async deactivate(id: string, actor: AuthenticatedUser) {
    if (id === actor.id) {
      throw new ForbiddenException('Anda tidak dapat menonaktifkan akun sendiri.');
    }

    const targetUser = await this.prisma.user.findUnique({ where: { id } });
    if (!targetUser) {
      throw new NotFoundException('Pegawai tidak ditemukan.');
    }

    return this.prisma.user.update({
      where: { id },
      data: { isActive: false },
      select: this._safeUserSelect(),
    });
  }

  async reactivate(id: string) {
    const targetUser = await this.prisma.user.findUnique({ where: { id } });
    if (!targetUser) {
      throw new NotFoundException('Pegawai tidak ditemukan.');
    }

    return this.prisma.user.update({
      where: { id },
      data: { isActive: true },
      select: this._safeUserSelect(),
    });
  }

  /// Select terpusat yang MENGECUALIKAN passwordHash - dipakai di
  /// SETIAP query user di service ini, supaya tidak ada satu pun
  /// query yang lupa mengecualikan field sensitif tsb.
  private _safeUserSelect() {
    return {
      id: true,
      nip: true,
      fullName: true,
      email: true,
      phoneNumber: true,
      instansiName: true,
      unitKerja: true,
      isActive: true,
      lastLoginAt: true,
      createdAt: true,
      updatedAt: true,
      role: {
        select: { id: true, name: true },
      },
    };
  }
}
