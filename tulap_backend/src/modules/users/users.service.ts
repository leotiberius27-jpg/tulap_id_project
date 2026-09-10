import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, RoleName } from '@prisma/client';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { S3StorageService } from '../../infrastructure/storage/s3-storage.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { QueryUsersDto } from './dto/query-users.dto';
import { UpdateOwnProfileDto } from './dto/update-own-profile.dto';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: S3StorageService,
  ) {}

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

    try {
      return await this.prisma.user.update({
        where: { id },
        data: {
          // `nip` unik di database (nullable, tapi TIDAK boleh string
          // kosong ganda - Postgres menganggap "" sama dengan "" pada
          // constraint unique, beda dengan NULL yang boleh berulang).
          // String kosong dari form HARUS dikonversi ke null di sini,
          // bukan diteruskan apa adanya - kalau tidak, akun kedua yang
          // NIP-nya dikosongkan akan gagal disimpan dengan error 500
          // "Unique constraint failed on the fields: (nip)".
          nip: dto.nip === undefined ? undefined : dto.nip.trim() || null,
          fullName: dto.fullName,
          phoneNumber: dto.phoneNumber,
          instansiName: dto.instansiName,
          unitKerja: dto.unitKerja,
          isActive: dto.isActive,
          roleId,
        },
        select: this._safeUserSelect(),
      });
    } catch (error) {
      this._rethrowIfDuplicateNip(error);
      throw error;
    }
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

  /// Update profil DIRI SENDIRI (nama, telepon, instansi, NIP) - dipakai
  /// layar "Edit Profil" mobile. Berbeda dari `update()` (Admin lewat
  /// PATCH /users/:id): tidak menerima roleName/isActive/unitKerja,
  /// dan tidak butuh @Roles() khusus - berlaku untuk semua role yang
  /// sudah login, termasuk PEGAWAI biasa mengubah datanya sendiri.
  async updateOwnProfile(userId: string, dto: UpdateOwnProfileDto) {
    try {
      return await this.prisma.user.update({
        where: { id: userId },
        data: {
          fullName: dto.fullName,
          phoneNumber: dto.phoneNumber,
          instansiName: dto.instansiName,
          // Lihat catatan di `update()` - string kosong harus jadi null,
          // bukan diteruskan mentah, atau constraint unique `nip` akan
          // membentur baris lain yang juga kosong (mis. akun Google/self-
          // register lain yang belum punya NIP) dan gagal dengan 500.
          nip: dto.nip === undefined ? undefined : dto.nip.trim() || null,
        },
        select: this._safeUserSelect(),
      });
    } catch (error) {
      this._rethrowIfDuplicateNip(error);
      throw error;
    }
  }

  /// Mengubah error mentah Prisma P2002 (unique constraint) pada kolom
  /// `nip` jadi pesan jelas untuk user, bukan 500 generik. Constraint
  /// lain (mis. `email`) tidak disentuh endpoint ini jadi tidak perlu
  /// dibedakan lagi - satu-satunya kolom unik yang di-update di sini.
  private _rethrowIfDuplicateNip(error: unknown): void {
    if (
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      throw new BadRequestException(
        'NIP tersebut sudah terdaftar pada akun lain.',
      );
    }
  }

  /// Unggah/ganti foto profil sendiri ke S3 (bukan disimpan sebagai path
  /// lokal device seperti sebelumnya - itu sebabnya foto profil hilang
  /// begitu app di-reinstall/ganti perangkat). Foto lama (jika ada dan
  /// memang tersimpan di bucket kita, bukan foto Google/dsb) dihapus
  /// agar tidak menumpuk file yatim di storage.
  async updateOwnPhoto(userId: string, file: Express.Multer.File) {
    const currentUser = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { photoUrl: true },
    });

    const { url } = await this.storage.uploadFile({
      buffer: file.buffer,
      mimeType: file.mimetype,
      category: 'avatar',
    });

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { photoUrl: url },
      select: this._safeUserSelect(),
    });

    const oldKey = this.storage.keyFromUrl(currentUser?.photoUrl);
    if (oldKey && oldKey.startsWith('avatar/')) {
      await this.storage.deleteFile(oldKey).catch(() => {
        // Kegagalan hapus foto lama tidak boleh membatalkan penggantian
        // foto baru yang sudah berhasil - cukup jadi file yatim, bukan
        // error fatal bagi user.
      });
    }

    return updated;
  }

  /// Menghapus foto profil sendiri (tombol "Hapus Foto Profil" di
  /// mobile) - hapus file di S3 (jika memang milik bucket kita) dan
  /// kosongkan `photoUrl` di database.
  async deleteOwnPhoto(userId: string) {
    const currentUser = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { photoUrl: true },
    });

    const updated = await this.prisma.user.update({
      where: { id: userId },
      data: { photoUrl: null },
      select: this._safeUserSelect(),
    });

    const oldKey = this.storage.keyFromUrl(currentUser?.photoUrl);
    if (oldKey && oldKey.startsWith('avatar/')) {
      await this.storage.deleteFile(oldKey).catch(() => {});
    }

    return updated;
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
      photoUrl: true,
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
