import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/**
 * Decorator @Public()
 * ----------------------------------------------------------------------
 * Karena JwtAuthGuard dipasang secara global (proteksi default di semua
 * endpoint), kita butuh cara eksplisit untuk MENGECUALIKAN endpoint
 * tertentu yang memang harus bisa diakses tanpa login — contoh utama:
 * POST /auth/login.
 *
 * Filosofi "secure by default, explicit opt-out" ini lebih aman
 * dibanding sebaliknya (open by default, explicit opt-in), karena
 * developer baru tidak akan lupa memproteksi endpoint baru.
 * ----------------------------------------------------------------------
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
