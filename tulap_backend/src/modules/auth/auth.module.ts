import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuditModule } from '../audit/audit.module';
import { MailerModule } from '../../infrastructure/mailer/mailer.module';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { OAuthVerifierService } from './oauth-verifier.service';
import { JwtStrategy } from './strategies/jwt.strategy';

@Module({
  imports: [
    AuditModule,
    MailerModule,
    PassportModule.register({ defaultStrategy: 'jwt' }),
    // Registrasi async agar JWT_SECRET dibaca dari ConfigService,
    // bukan hardcode — mendukung env terpisah per environment
    // (dev/staging/production) sesuai praktik keamanan yang baik.
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: configService.get<string>('JWT_SECRET'),
        signOptions: {
          expiresIn: configService.get<string>('JWT_ACCESS_EXPIRES_IN', '15m'),
        },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, OAuthVerifierService],
  exports: [AuthService],
})
export class AuthModule {}
