import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { RoleName } from '@prisma/client';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { AuthenticatedUser } from '../../modules/auth/interfaces/authenticated-user.interface';

/**
 * RolesGuard
 * ----------------------------------------------------------------------
 * Guard lapis kedua (dijalankan SETELAH JwtAuthGuard, sehingga
 * `request.user` dipastikan sudah terisi). Guard ini membaca metadata
 * role yang didefinisikan lewat decorator @Roles(...) di controller,
 * lalu mencocokkannya dengan role user yang sedang login.
 *
 * Aturan RBAC Tulap.id:
 *  - Jika endpoint TIDAK diberi @Roles(), maka endpoint tsb bisa
 *    diakses oleh SEMUA role yang sudah login (hanya butuh JwtAuthGuard).
 *  - Jika endpoint diberi @Roles(ADMIN, SUPER_ADMIN), maka HANYA role
 *    tsb yang boleh lewat — role lain ditolak dengan 403 Forbidden.
 *  - SUPER_ADMIN TIDAK otomatis bisa akses semua endpoint secara diam-
 *    diam; setiap endpoint sensitif tetap harus mencantumkan SUPER_ADMIN
 *    secara eksplisit di daftar @Roles() agar kontrol akses tetap
 *    auditable dan tidak ada "hak akses tersembunyi".
 * ----------------------------------------------------------------------
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    // Ambil daftar role yang diizinkan dari metadata handler ATAU class.
    const requiredRoles = this.reflector.getAllAndOverride<RoleName[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    // Tidak ada pembatasan role spesifik -> cukup harus sudah login.
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user: AuthenticatedUser | undefined = request.user;

    if (!user) {
      throw new ForbiddenException('Data pengguna tidak ditemukan pada sesi.');
    }

    const isAllowed = requiredRoles.includes(user.role);

    if (!isAllowed) {
      throw new ForbiddenException(
        `Akses ditolak. Role '${user.role}' tidak memiliki izin untuk mengakses resource ini.`,
      );
    }

    return true;
  }
}
