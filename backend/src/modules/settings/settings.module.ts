import { Module } from '@nestjs/common';
import { SettingsService } from './settings.service';
import { BrandingController } from './branding.controller';

@Module({
  controllers: [BrandingController],
  providers: [SettingsService],
  exports: [SettingsService],
})
export class SettingsModule {}
