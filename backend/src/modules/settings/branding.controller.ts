import {
  BadRequestException,
  Controller,
  Delete,
  Get,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { extname } from 'path';
import { v4 as uuid } from 'uuid';
import { Role } from '@prisma/client';
import { SettingsService } from './settings.service';
import { BlobStorageService } from '../../common/storage/blob-storage.service';
import { Public } from '../../common/decorators/public.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';

const LOGO_KEY = 'branding.logoUrl';

@Controller('branding')
export class BrandingController {
  constructor(
    private readonly settings: SettingsService,
    private readonly storage: BlobStorageService,
  ) {}

  /** The current logo URL, or null to fall back to the app's bundled asset. */
  @Public()
  @Get()
  async getBranding() {
    return { logoUrl: await this.settings.get(LOGO_KEY) };
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Post('logo')
  @UseInterceptors(
    FileInterceptor('logo', {
      storage: memoryStorage(),
      fileFilter: (_req, file, cb) => {
        if (!file.mimetype.match(/^image\//)) {
          cb(new BadRequestException('Only image files are allowed'), false);
          return;
        }
        cb(null, true);
      },
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadLogo(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('Logo file is required');
    const ext = extname(file.originalname) || '.png';
    const logoUrl = await this.storage.uploadPublic(
      `branding/logo-${uuid()}${ext}`,
      file.buffer,
      file.mimetype,
    );
    await this.settings.set(LOGO_KEY, logoUrl);
    return { logoUrl };
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Delete('logo')
  async clearLogo() {
    await this.settings.remove(LOGO_KEY);
    return { logoUrl: null };
  }
}
