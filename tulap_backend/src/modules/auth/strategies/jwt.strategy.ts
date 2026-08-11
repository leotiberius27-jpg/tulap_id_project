import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import {
  AuthenticatedUser,
  JwtPayload,
} from '../interfaces/authenticated-user.interface';

/**
 * JwtStrategy
 * ----------------------------------------------------------------------
 * Strategi Passport untuk memvalidasi Bearer Token JWT di setiap
 * request yang dilindungi oleh JwtAuthGuard.
 *
 * Alur kerja:
 *  1. Ambil token dari header `Authorization: Bearer <token>`
 *  2. Verifikasi signature & masa berlaku token menggunakan JWT_SECRET
 *  3. Payload hasil decode (`JwtPayload`) masuk ke method `validate()`
 *  4. Lookup ulang user ke database — memastikan user masih aktif
 *     (isActive) dan belum dihapus, meski token-nya masih valid secara
 *     kriptografis. Ini penting untuk kasus user di-nonaktifkan admin
 *     di tengah masa berlaku token.
 *  5. Hasil return method validate() otomatis menjadi `request.user`
 * ----------------------------------------------------------------------
 */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET'),
    });
  }

  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: { role: true },
    });

    // Tolak akses jika user tidak ditemukan atau sudah dinonaktifkan,
    // walaupun token JWT-nya sendiri masih valid.
    if (!user || !user.isActive) {
      throw new UnauthorizedException(
        'Akun tidak ditemukan atau sudah dinonaktifkan.',
      );
    }

    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      role: user.role.name,
      instansiName: user.instansiName,
    };
  }
}
