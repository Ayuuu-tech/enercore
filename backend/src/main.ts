import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { PrismaExceptionFilter } from './common/filters/prisma-exception.filter';
import * as express from 'express';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Serve uploaded files as static assets
  const uploadsPath = join(__dirname, '..', '..', 'uploads');
  app.use('/uploads', express.static(uploadsPath));

  // Set global API prefix
  app.setGlobalPrefix('api');

  // Enable CORS
  app.enableCors();

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
  console.log(`Enercore Backend is running on: http://localhost:${port}/api`);
}
bootstrap();
