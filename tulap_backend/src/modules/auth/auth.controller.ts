import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { RoleName } from '@prisma/client';
import { AuthService } from './auth.service';
import { AppleAuthDto } from './dto/apple-auth.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { SelfRegisterDto } from './dto/self-register.dto';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AuthenticatedUser } from './interfaces/authenticated-user.interface';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * POST /auth/login
   * Endpoint publik (tidak butuh token) — titik masuk utama mobile app
   * & web dashboard untuk mendapatkan Access Token + Refresh Token.
   */
  // Rate limit ketat khusus login (5x/menit per IP) - mencegah brute
  // force credential guessing (Bagian 30 dokumen spesifikasi).
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @Public()
  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  /**
   * POST /auth/register
   * HANYA bisa diakses oleh ADMIN atau SUPER_ADMIN. Pegawai tidak bisa
   * mendaftarkan akun sendiri — sesuai kebijakan instansi pemerintah
   * bahwa akses sistem harus melalui provisioning oleh admin.
   */
  @Roles(RoleName.ADMIN, RoleName.SUPER_ADMIN)
  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  register(@Body() dto: RegisterDto, @CurrentUser() actor: AuthenticatedUser) {
    return this.authService.register(dto, actor);
  }

  /**
   * POST /auth/refresh
   * Endpoint publik dari sisi JwtAuthGuard (yang divalidasi bukan
   * Access Token, melainkan Refresh Token di dalam body request).
   */
  @Public()
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshTokenDto) {
    return this.authService.refreshAccessToken(dto.refreshToken);
  }

  /**
   * GET /auth/profile
   * Contoh endpoint terproteksi sederhana — mengembalikan data user
   * yang sedang login berdasarkan token JWT aktif.
   */
  @Get('profile')
  getProfile(@CurrentUser() user: AuthenticatedUser) {
    return user;
  }

  /**
   * POST /auth/register-self
   * Endpoint publik - pendaftaran mandiri dari mobile app (layar
   * "Daftar"). SELALU membuat akun ber-role PEGAWAI, berbeda dari
   * POST /auth/register yang hanya bisa dipanggil Admin.
   */
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @Public()
  @Post('register-self')
  @HttpCode(HttpStatus.CREATED)
  registerSelf(@Body() dto: SelfRegisterDto) {
    return this.authService.selfRegister(dto);
  }

  /**
   * POST /auth/forgot-password
   * Langkah 1 alur "Lupa Kata Sandi" - kirim kode OTP 6-digit ke email
   * jika terdaftar. Rate limit ketat mencegah spam pengiriman email.
   */
  @Throttle({ default: { ttl: 60_000, limit: 3 } })
  @Public()
  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.authService.forgotPassword(dto);
  }

  /**
   * POST /auth/reset-password
   * Langkah 2 alur "Lupa Kata Sandi" - tukar kode OTP dengan password
   * baru.
   */
  @Throttle({ default: { ttl: 60_000, limit: 5 } })
  @Public()
  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto);
  }

  /**
   * POST /auth/google
   * Masuk/daftar otomatis lewat Google Sign-In - idToken diverifikasi
   * di server (lihat OAuthVerifierService), tidak pernah dipercaya
   * mentah-mentah dari mobile.
   */
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @Public()
  @Post('google')
  @HttpCode(HttpStatus.OK)
  loginWithGoogle(@Body() dto: GoogleAuthDto) {
    return this.authService.loginWithGoogle(dto);
  }

  /**
   * POST /auth/apple
   * Masuk/daftar otomatis lewat Sign In with Apple - identityToken
   * diverifikasi di server via JWKS Apple.
   */
  @Throttle({ default: { ttl: 60_000, limit: 10 } })
  @Public()
  @Post('apple')
  @HttpCode(HttpStatus.OK)
  loginWithApple(@Body() dto: AppleAuthDto) {
    return this.authService.loginWithApple(dto);
  }
}
