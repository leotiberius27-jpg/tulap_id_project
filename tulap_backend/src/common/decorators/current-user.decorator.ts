import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AuthenticatedUser } from '../../modules/auth/interfaces/authenticated-user.interface';

/**
 * Decorator @CurrentUser()
 * ----------------------------------------------------------------------
 * Shortcut untuk mengambil data user yang sedang login (hasil validasi
 * JwtStrategy) langsung di parameter controller, tanpa perlu menulis
 * `req.user` berulang-ulang di setiap handler.
 *
 * Contoh pemakaian:
 *   @Get('profile')
 *   getProfile(@CurrentUser() user: AuthenticatedUser) { ... }
 * ----------------------------------------------------------------------
 */
export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): AuthenticatedUser => {
    const request = ctx.switchToHttp().getRequest();
    return request.user;
  },
);
