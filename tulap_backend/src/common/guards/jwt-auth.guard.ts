import {
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';

/**
 * JwtAuthGuard
 * ----------------------------------------------------------------------
 * Guard lapis pertama: memastikan request membawa token JWT yang valid.
 * Dipasang secara GLOBAL di main.ts (APP_GUARD) sehingga SEMUA endpoint
 * ter-proteksi secara default ("secure by default"), kecuali endpoint
 * yang ditandai @Public() (mis. /auth/login, /auth/refresh).
 * ----------------------------------------------------------------------
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly reflector: Reflector) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(
      IS_PUBLIC_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (isPublic) {
      return true;
    }
    return super.canActivate(context);
  }

  handleRequest<TUser = any>(err: any, user: any): TUser {
    if (err || !user) {
      throw (
        err ||
        new UnauthorizedException(
          'Sesi tidak valid atau telah berakhir. Silakan login kembali.',
        )
      );
    }
    return user;
  }
}
