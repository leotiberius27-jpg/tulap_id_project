jest.mock('jwks-rsa', () => {
  return {
    __esModule: true,
    default: jest.fn(),
    jwksRsa: jest.fn(),
    JwksClient: jest.fn().mockImplementation(() => ({
      getSigningKey: jest.fn(),
    })),
  };
});

import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException, BadRequestException, NotFoundException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { MailerService } from '../../infrastructure/mailer/mailer.service';
import { AuditService } from '../audit/audit.service';
import { OAuthVerifierService } from './oauth-verifier.service';
import * as bcrypt from 'bcrypt';

describe('AuthService', () => {
  let service: AuthService;
  let prisma: any;
  let jwtService: any;
  let audit: any;
  let mailer: any;
  let oauthVerifier: any;

  beforeEach(async () => {
    prisma = {
      user: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      role: {
        findUnique: jest.fn(),
      },
    };

    jwtService = {
      signAsync: jest.fn().mockResolvedValue('test_token'),
      verifyAsync: jest.fn(),
    };

    audit = {
      record: jest.fn().mockResolvedValue(undefined),
    };

    mailer = {
      sendPasswordResetCode: jest.fn().mockResolvedValue(undefined),
    };

    oauthVerifier = {
      verifyGoogleIdToken: jest.fn(),
      verifyAppleIdentityToken: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prisma },
        { provide: JwtService, useValue: jwtService },
        { provide: AuditService, useValue: audit },
        { provide: MailerService, useValue: mailer },
        { provide: OAuthVerifierService, useValue: oauthVerifier },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('login', () => {
    it('should throw UnauthorizedException if user not found', async () => {
      prisma.user.findUnique.mockResolvedValue(null);

      await expect(
        service.login({ email: 'unknown@tulap.id', password: 'password' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException if user is inactive', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: '1',
        email: 'inactive@tulap.id',
        isActive: false,
      });

      await expect(
        service.login({ email: 'inactive@tulap.id', password: 'password' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw UnauthorizedException if password does not match', async () => {
      const passwordHash = await bcrypt.hash('correct_password', 10);
      prisma.user.findUnique.mockResolvedValue({
        id: '1',
        email: 'user@tulap.id',
        passwordHash,
        isActive: true,
        role: { name: 'PEGAWAI' },
      });

      await expect(
        service.login({ email: 'user@tulap.id', password: 'wrong_password' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should successfully log in and return tokens on valid credentials', async () => {
      const passwordHash = await bcrypt.hash('correct_password', 10);
      prisma.user.findUnique.mockResolvedValue({
        id: 'user_123',
        email: 'budi@tulap.id',
        fullName: 'Budi Santoso',
        passwordHash,
        isActive: true,
        role: { name: 'PEGAWAI' },
      });
      prisma.user.update.mockResolvedValue({});

      const result = await service.login({
        email: 'budi@tulap.id',
        password: 'correct_password',
      });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.email).toBe('budi@tulap.id');
    });
  });
});
