import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Mobile app (dan web) mengakses backend dari origin berbeda.
  app.enableCors();

  // Validasi global berbasis class-validator untuk semua DTO
  // (whitelist: buang field yang tidak dideklarasikan di DTO,
  // transform: ubah payload plain JSON menjadi instance class DTO).
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
}

bootstrap();
