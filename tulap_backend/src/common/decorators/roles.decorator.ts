import { SetMetadata } from '@nestjs/common';
import { RoleName } from '@prisma/client';

export const ROLES_KEY = 'roles';

/**
 * Decorator @Roles(...)
 * ----------------------------------------------------------------------
 * Digunakan di atas controller/handler untuk menandai role apa saja
 * yang diizinkan mengakses endpoint tersebut. Nilai role diambil dari
 * enum RoleName yang sama persis dengan skema Prisma (roles.decorator.ts
 * ini tidak boleh out-of-sync dengan schema.prisma).
 *
 * Contoh pemakaian:
 *   @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
 *   @Get('users')
 *   findAllUsers() { ... }
 * ----------------------------------------------------------------------
 */
export const Roles = (...roles: RoleName[]) => SetMetadata(ROLES_KEY, roles);
