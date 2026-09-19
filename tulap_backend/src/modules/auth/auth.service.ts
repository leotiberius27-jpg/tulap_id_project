import {
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { RoleName } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { App, cert, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { MailerService } from '../../infrastructure/mailer/mailer.service';
import { AuditService } from '../audit/audit.service';
import { AppleAuthDto } from './dto/apple-auth.dto';
import { FacebookAuthDto } from './dto/facebook-auth.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { SelfRegisterDto } from './dto/self-register.dto';
import { AuthenticatedUser, JwtPayload } from './interfaces/authenticated-user.interface';
import { OAuthVerifierService, VerifiedOAuthProfile } from './oauth-verifier.service';

const SALT_ROUNDS = 12; // Cost factor bcrypt - seimbang antara keamanan & performa
const RESET_CODE_TTL_MINUTES = 15;

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private firebaseAdminApp: App | null = null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly audit: AuditService,
    private readonly mailer: MailerService,
    private readonly oauthVerifier: OAuthVerifierService,
    private readonly config: ConfigService,
  ) {
    // Kredensial SAMA dengan FirestoreSyncService/PushNotificationService
    // (FIREBASE_SERVICE_ACCOUNT_JSON) - satu service account Firebase
    // dipakai bersama, app diberi nama sendiri ('tulap-auth') karena
    // firebase-admin melarang initializeApp() dipanggil dua kali dengan
    // nama yang sama dari service berbeda.
    const raw = this.config.get<string>('FIREBASE_SERVICE_ACCOUNT_JSON');
    if (raw) {
      try {
        const credentials = JSON.parse(raw);
        this.firebaseAdminApp = initializeApp(
          { credential: cert(credentials) },
          'tulap-auth',
        );
      } catch (err) {
        this.logger.error(
          `FIREBASE_SERVICE_ACCOUNT_JSON tidak valid - Firebase custom token dinonaktifkan: ${err}`,
        );
      }
    }
  }

  /**
   * Menerbitkan Firebase custom auth token dengan UID SAMA PERSIS dengan
   * `User.id` Tulap.id (Postgres) - BUKAN UID Firebase yang baru/acak.
   * Ini membuat sisi mobile bisa `signInWithCustomToken()` ke Firebase
   * Authentication (dibutuhkan modul live location tracking di
   * `features/firebase_live_tracking/`, yang security rules-nya
   * mensyaratkan `request.auth.uid`) TANPA membuat identitas kedua yang
   * terpisah dari akun Tulap.id sesungguhnya - satu ID dipakai di
   * Postgres, JWT Tulap.id, DAN Firestore sekaligus, sehingga dokumen
   * `live_locations/{userId}` bisa langsung dikorelasikan ke pegawai
   * yang sebenarnya. Best-effort: mengembalikan `undefined` (bukan
   * melempar) jika Firebase belum dikonfigurasi/gagal - login utama
   * TIDAK PERNAH boleh gagal gara-gara ini.
   */
  private async mintFirebaseCustomToken(
    userId: string,
  ): Promise<string | undefined> {
    if (!this.firebaseAdminApp) return undefined;
    try {
      return await getAuth(this.firebaseAdminApp).createCustomToken(userId);
    } catch (err) {
      this.logger.warn(
        `Gagal membuat Firebase custom token untuk user ${userId}: ${err}`,
      );
      return undefined;
    }
  }

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

    if (!user.passwordHash) {
      // Akun ini dibuat lewat Google/Apple Sign-In dan tidak pernah
      // punya password lokal - arahkan ke tombol OAuth yang sesuai
      // alih-alih pesan generik yang membingungkan.
      throw new UnauthorizedException(
        'Akun ini terdaftar lewat Google/Apple. Gunakan tombol "Lanjutkan dengan Google/Apple" untuk masuk.',
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
        nip: user.nip,
        fullName: user.fullName,
        email: user.email,
        role: user.role.name,
        instansiName: user.instansiName,
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoUrl,
      },
    };
  }

  /**
   * Registrasi user baru. Endpoint pemanggil WAJIB dibatasi hanya untuk
   * ADMIN/SUPER_ADMIN via @Roles() di controller — service ini tidak
   * melakukan pengecekan role pemanggil, itu tanggung jawab RolesGuard.
   */
  async register(dto: RegisterDto, actor: AuthenticatedUser) {
    // Cegah eskalasi privilege: ADMIN (non-SUPER_ADMIN) tidak boleh
    // membuat akun ber-role SUPER_ADMIN. Mencerminkan aturan yang sama
    // di UsersService.update untuk perubahan role user yang sudah ada.
    if (dto.roleName === RoleName.SUPER_ADMIN && actor.role !== RoleName.SUPER_ADMIN) {
      throw new ForbiddenException(
        'Hanya Super Admin yang dapat mendaftarkan akun Super Admin.',
      );
    }

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

    await this.audit.log({
      actorId: actor.id,
      action: 'USER_CREATED',
      entity: 'User',
      entityId: newUser.id,
      metadata: { email: newUser.email, role: newUser.role.name },
    });

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

  /**
   * Registrasi mandiri (self-registration) dari mobile app - endpoint
   * PUBLIK (Public()), berbeda dari `register()` yang hanya bisa
   * dipanggil Admin. SELALU membuat akun ber-role PEGAWAI dan aktif
   * langsung (Bagian "Daftar" mobile - user dapat langsung memakai
   * akunnya begitu mendaftar, tanpa menunggu persetujuan Admin).
   */
  async selfRegister(dto: SelfRegisterDto) {
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existingUser) {
      throw new ConflictException('Email sudah terdaftar di sistem.');
    }

    const pegawaiRole = await this.prisma.role.findUnique({
      where: { name: RoleName.PEGAWAI },
    });

    if (!pegawaiRole) {
      throw new NotFoundException('Role PEGAWAI belum terdaftar di master data.');
    }

    const passwordHash = await bcrypt.hash(dto.password, SALT_ROUNDS);

    const newUser = await this.prisma.user.create({
      data: {
        fullName: dto.fullName,
        email: dto.email,
        passwordHash,
        phoneNumber: dto.phoneNumber,
        instansiName: dto.instansiName,
        isSelfRegistered: true,
        roleId: pegawaiRole.id,
      },
      include: { role: true },
    });

    this.logger.log(`Registrasi mandiri baru: ${newUser.email}`);

    await this.audit.log({
      actorId: newUser.id,
      action: 'USER_SELF_REGISTERED',
      entity: 'User',
      entityId: newUser.id,
      metadata: { email: newUser.email },
    });

    const tokens = await this.generateTokens({
      sub: newUser.id,
      email: newUser.email,
      role: newUser.role.name,
    });

    return {
      ...tokens,
      user: {
        id: newUser.id,
        nip: newUser.nip,
        fullName: newUser.fullName,
        email: newUser.email,
        role: newUser.role.name,
        instansiName: newUser.instansiName,
        phoneNumber: newUser.phoneNumber,
        photoUrl: newUser.photoUrl,
      },
    };
  }

  /**
   * Langkah 1 Lupa Kata Sandi: generate kode OTP 6-digit, simpan HASH-nya
   * (bukan kode mentah - sama seperti password) + waktu kedaluwarsa, lalu
   * kirim via MailerService. Respons SELALU sama persis baik email
   * terdaftar maupun tidak (cegah user enumeration, sama seperti login).
   */
  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });

    if (user && user.isActive) {
      const code = crypto.randomInt(100000, 999999).toString();
      const codeHash = await bcrypt.hash(code, SALT_ROUNDS);
      const expiresAt = new Date(Date.now() + RESET_CODE_TTL_MINUTES * 60_000);

      await this.prisma.user.update({
        where: { id: user.id },
        data: {
          passwordResetCodeHash: codeHash,
          passwordResetExpiresAt: expiresAt,
        },
      });

      try {
        await this.mailer.sendPasswordResetCode(user.email, code);
      } catch (error) {
        this.logger.error(`Gagal mengirim email reset ke ${user.email}: ${error}`);
      }
    }

    return {
      message:
        'Jika email terdaftar, kode reset kata sandi telah dikirim. Periksa kotak masuk Anda.',
    };
  }

  /**
   * Langkah 2 Lupa Kata Sandi: validasi kode OTP terhadap hash tersimpan
   * + belum kedaluwarsa, lalu ganti password dan hapus kode (sekali pakai).
   */
  async resetPassword(dto: ResetPasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });

    if (
      !user ||
      !user.passwordResetCodeHash ||
      !user.passwordResetExpiresAt ||
      user.passwordResetExpiresAt < new Date()
    ) {
      throw new UnauthorizedException('Kode reset tidak valid atau telah kedaluwarsa.');
    }

    const isCodeValid = await bcrypt.compare(dto.code, user.passwordResetCodeHash);
    if (!isCodeValid) {
      throw new UnauthorizedException('Kode reset tidak valid atau telah kedaluwarsa.');
    }

    const passwordHash = await bcrypt.hash(dto.newPassword, SALT_ROUNDS);

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        passwordHash,
        passwordResetCodeHash: null,
        passwordResetExpiresAt: null,
      },
    });

    await this.audit.log({
      actorId: user.id,
      action: 'PASSWORD_RESET',
      entity: 'User',
      entityId: user.id,
      metadata: {},
    });

    this.logger.log(`Password direset via kode OTP: ${user.email}`);

    return { message: 'Kata sandi berhasil diganti. Silakan masuk dengan kata sandi baru.' };
  }

  async loginWithGoogle(dto: GoogleAuthDto) {
    const profile = await this.oauthVerifier.verifyGoogleIdToken(dto.idToken);
    return this.loginOrCreateFromOAuth(profile, 'googleId');
  }

  async loginWithApple(dto: AppleAuthDto) {
    const profile = await this.oauthVerifier.verifyAppleIdentityToken(
      dto.identityToken,
      dto.fullName,
    );
    return this.loginOrCreateFromOAuth(profile, 'appleId');
  }

  async loginWithFacebook(dto: FacebookAuthDto) {
    const profile = await this.oauthVerifier.verifyFacebookAccessToken(
      dto.accessToken,
    );
    return this.loginOrCreateFromOAuth(profile, 'facebookId');
  }

  /**
   * Dipakai bersama oleh Google & Apple Sign-In: cari akun via id
   * provider dulu (sumber kebenaran utama - email bisa berubah/kosong
   * di login Apple berikutnya), baru fallback ke email untuk MENAUTKAN
   * akun password yang sudah ada, baru terakhir membuat akun PEGAWAI
   * baru jika benar-benar belum pernah terdaftar sama sekali.
   */
  private async loginOrCreateFromOAuth(
    profile: VerifiedOAuthProfile,
    providerIdField: 'googleId' | 'appleId' | 'facebookId',
  ) {
    let user = await this.prisma.user.findFirst({
      where: { [providerIdField]: profile.providerId },
      include: { role: true },
    });

    if (!user && profile.email) {
      const existingByEmail = await this.prisma.user.findUnique({
        where: { email: profile.email },
        include: { role: true },
      });

      if (existingByEmail) {
        user = await this.prisma.user.update({
          where: { id: existingByEmail.id },
          data: { [providerIdField]: profile.providerId },
          include: { role: true },
        });
      }
    }

    if (!user) {
      if (!profile.email) {
        throw new UnauthorizedException(
          'Tidak dapat membuat akun baru tanpa email. Coba masuk dengan email/password atau hubungi Admin.',
        );
      }

      const pegawaiRole = await this.prisma.role.findUnique({
        where: { name: RoleName.PEGAWAI },
      });
      if (!pegawaiRole) {
        throw new NotFoundException('Role PEGAWAI belum terdaftar di master data.');
      }

      user = await this.prisma.user.create({
        data: {
          fullName: profile.fullName || profile.email.split('@')[0],
          email: profile.email,
          isSelfRegistered: true,
          roleId: pegawaiRole.id,
          [providerIdField]: profile.providerId,
        },
        include: { role: true },
      });

      await this.audit.log({
        actorId: user.id,
        action: 'USER_SELF_REGISTERED',
        entity: 'User',
        entityId: user.id,
        metadata: { email: user.email, via: providerIdField },
      });
    }

    if (!user.isActive) {
      throw new UnauthorizedException(
        'Akun Anda telah dinonaktifkan. Hubungi Admin instansi.',
      );
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });

    const [tokens, firebaseToken] = await Promise.all([
      this.generateTokens({
        sub: user.id,
        email: user.email,
        role: user.role.name,
      }),
      this.mintFirebaseCustomToken(user.id),
    ]);

    return {
      ...tokens,
      firebaseToken,
      user: {
        id: user.id,
        nip: user.nip,
        fullName: user.fullName,
        email: user.email,
        role: user.role.name,
        instansiName: user.instansiName,
        phoneNumber: user.phoneNumber,
        photoUrl: user.photoUrl,
      },
    };
  }
}
