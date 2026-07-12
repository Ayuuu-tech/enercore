import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger, ValidationPipe } from '@nestjs/common';
import { PrismaExceptionFilter } from './common/filters/prisma-exception.filter';
import * as express from 'express';
import helmet from 'helmet';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Security headers.
  app.use(helmet());

  // Serve uploaded files as static assets
  const uploadsPath = join(__dirname, '..', '..', 'uploads');
  app.use('/uploads', express.static(uploadsPath));

  // Set global API prefix
  app.setGlobalPrefix('api');

  // Browser callers are restricted to the origins we configure. The mobile app
  // is not a browser — it sends no Origin header — so it is unaffected. With
  // CORS_ORIGINS unset, no cross-origin browser app may call the API.
  const origins = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  app.enableCors({
    origin: origins.length > 0 ? origins : false,
    credentials: true,
  });

  // Use global ValidationPipes for DTO requests validation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  // Use global Prisma Database constraints exception filter
  app.useGlobalFilters(new PrismaExceptionFilter());

  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');
  Logger.log(`Enercore backend running on http://localhost:${port}/api`, 'Bootstrap');
}
bootstrap();
