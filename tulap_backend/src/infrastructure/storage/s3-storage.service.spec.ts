import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { S3StorageService } from './s3-storage.service';

describe('S3StorageService', () => {
  let service: S3StorageService;
  let configService: any;

  beforeEach(async () => {
    configService = {
      get: jest.fn((key: string, defaultValue?: string) => {
        switch (key) {
          case 'S3_BUCKET_NAME':
            return 'tulap-evidence';
          case 'S3_PUBLIC_URL_BASE':
            return 'https://storage.tulap.id/tulap-evidence';
          case 'S3_ENDPOINT':
            return undefined;
          case 'S3_REGION':
            return 'ap-southeast-3';
          case 'S3_ACCESS_KEY':
            return 'test_access_key';
          case 'S3_SECRET_KEY':
            return 'test_secret_key';
          default:
            return defaultValue;
        }
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        S3StorageService,
        { provide: ConfigService, useValue: configService },
      ],
    }).compile();

    service = module.get<S3StorageService>(S3StorageService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should have correct configuration', () => {
    expect(configService.get).toHaveBeenCalledWith('S3_BUCKET_NAME');
    expect(configService.get).toHaveBeenCalledWith('S3_PUBLIC_URL_BASE');
  });
});
