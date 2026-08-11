import {
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { JwtPayload } from './interfaces/authenticated-user.interface';

const SALT_ROUNDS = 12; // Cost factor bcrypt - seimbang antara keamanan & performa

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  /**
   * Proses login: verifikasi kredensial lalu terbitkan Access Token
   * & Refresh Token.
   */
  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
      include: { role: true },
    });

    // Pesan error SENGAJA digeneralisasi (tidak membedakan "email tidak
    // ditemukan" vs "password salah") untuk mencegah user enumeration attack.
    if (!user) {
      throw new UnauthorizedException('Email atau password salah.');
    }

    if (!user.isActive) {
      throw new UnauthorizedException(
        'Akun Anda telah dinonaktifkan. Hubungi Admin instansi.',
      );
    }

    const isPasswordValid = await bcrypt.compare(
      dto.password,
      user.passwordHash,
    );

    if (!isPasswordValid) {
      throw new UnauthorizedException('Email atau password salah.');
    }

    // Update waktu login terakhir (audit trail sederhana)
    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    const tokens = await this.generateTokens({
      sub: user.id,
      email: user.email,
      role: user.role.name,
    });

    this.logger.log(`User ${user.email} berhasil login.`);

    return {
      ...tokens,
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        role: user.role.name,
        instansiName: user.instansiName,
      },
    };
  }

  /**
   * Registrasi user baru. Endpoint pemanggil WAJIB dibatasi hanya untuk
   * ADMIN/SUPER_ADMIN via @Roles() di controller — service ini tidak
   * melakukan pengecekan role pemanggil, itu tanggung jawab RolesGuard.
   */
  async register(dto: RegisterDto) {
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existingUser) {
      throw new ConflictException('Email sudah terdaftar di sistem.');
    }

    const role = await this.prisma.role.findUnique({
      where: { name: dto.roleName },
    });

    if (!role) {
      throw new NotFoundException(
        `Role '${dto.roleName}' belum terdaftar di master data.`,
      );
    }

    const passwordHash = await bcrypt.hash(dto.password, SALT_ROUNDS);

    const newUser = await this.prisma.user.create({
      data: {
        nip: dto.nip,
        fullName: dto.fullName,
        email: dto.email,
        passwordHash,
        phoneNumber: dto.phoneNumber,
        instansiName: dto.instansiName,
        unitKerja: dto.unitKerja,
        roleId: role.id,
      },
      include: { role: true },
    });

    this.logger.log(
      `User baru terdaftar: ${newUser.email} dengan role ${newUser.role.name}`,
    );

    // Tidak mengembalikan passwordHash ke response demi keamanan.
    const { passwordHash: _omit, ...safeUser } = newUser;
    return safeUser;
  }

  /**
   * Menerbitkan pasangan Access Token (umur pendek) & Refresh Token
   * (umur panjang) sesuai payload JWT.
   */
  private async generateTokens(payload: JwtPayload) {
    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: process.env.JWT_SECRET,
        expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
      }),
      this.jwtService.signAsync(payload, {
        secret: process.env.JWT_REFRESH_SECRET,
        expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
      }),
    ]);

    return { accessToken, refreshToken };
  }

  /**
   * Menerbitkan Access Token baru menggunakan Refresh Token yang valid.
   * Dipanggil saat Access Token di mobile/web sudah kedaluwarsa.
   */
  async refreshAccessToken(refreshToken: string) {
    try {
      const payload = await this.jwtService.verifyAsync<JwtPayload>(
        refreshToken,
        { secret: process.env.JWT_REFRESH_SECRET },
      );

      // Pastikan user masih aktif sebelum menerbitkan token baru.
      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        include: { role: true },
      });

      if (!user || !user.isActive) {
        throw new UnauthorizedException('Sesi tidak valid.');
      }

      return this.generateTokens({
        sub: user.id,
        email: user.email,
        role: user.role.name,
      });
    } catch (error) {
      throw new UnauthorizedException(
        'Refresh token tidak valid atau telah kedaluwarsa. Silakan login kembali.',
      );
    }
  }
}
