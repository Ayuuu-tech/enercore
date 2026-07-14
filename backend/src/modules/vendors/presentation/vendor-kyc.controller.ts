import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  Post,
  Put,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { Role, VendorDocumentType } from '@prisma/client';
import { VendorKycService, KycDetails } from '../application/vendor-kyc.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../../users/domain/user.entity';

const DOC_TYPES = Object.values(VendorDocumentType) as string[];

@Controller('vendors/kyc')
@UseGuards(JwtAuthGuard, RolesGuard)
export class VendorKycController {
  constructor(private readonly kyc: VendorKycService) {}

  // ── Vendor's own KYC ──────────────────────────────────────────────────────

  @Get('me')
  @Roles(Role.VENDOR, Role.ADMIN)
  async myStatus(@CurrentUser() user: UserEntity) {
    return this.kyc.getStatus(user.id);
  }

  @Put('me')
  @Roles(Role.VENDOR)
  async saveDetails(@CurrentUser() user: UserEntity, @Body() body: KycDetails) {
    await this.kyc.saveDetails(user.id, body);
    return this.kyc.getStatus(user.id);
  }

  /**
   * Uploads one KYC document. Files are held in memory, then written straight
   * to private blob storage — never to the App Service disk, which a redeploy
   * wipes.
   */
  @Post('me/documents/:type')
  @Roles(Role.VENDOR)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  async upload(
    @CurrentUser() user: UserEntity,
    @Param('type') type: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    if (!DOC_TYPES.includes(type)) {
      throw new BadRequestException(`type must be one of: ${DOC_TYPES.join(', ')}`);
    }
    return this.kyc.uploadDocument(user.id, type as VendorDocumentType, file);
  }

  /** A short-lived link to one of the vendor's own documents. */
  @Get('me/documents/:type/url')
  @Roles(Role.VENDOR, Role.ADMIN)
  async myDocumentUrl(@CurrentUser() user: UserEntity, @Param('type') type: string) {
    if (!DOC_TYPES.includes(type)) throw new BadRequestException('Unknown document type');
    return this.kyc.documentUrl(user.id, type as VendorDocumentType, user.id, user.role);
  }

  // ── Admin review ──────────────────────────────────────────────────────────

  @Get()
  @Roles(Role.ADMIN)
  async list() {
    return this.kyc.listForAdmin();
  }

  @Get(':vendorId')
  @Roles(Role.ADMIN)
  async detail(@Param('vendorId') vendorId: string) {
    return this.kyc.getForAdmin(vendorId);
  }

  @Get(':vendorId/documents/:type/url')
  @Roles(Role.ADMIN)
  async documentUrl(
    @Param('vendorId') vendorId: string,
    @Param('type') type: string,
    @CurrentUser() user: UserEntity,
  ) {
    if (!DOC_TYPES.includes(type)) throw new BadRequestException('Unknown document type');
    return this.kyc.documentUrl(vendorId, type as VendorDocumentType, user.id, user.role);
  }

  @Post(':vendorId/approve')
  @Roles(Role.ADMIN)
  async approve(@Param('vendorId') vendorId: string) {
    return this.kyc.approve(vendorId);
  }

  @Post(':vendorId/reject')
  @Roles(Role.ADMIN)
  async reject(@Param('vendorId') vendorId: string, @Body() body: { reason: string }) {
    return this.kyc.reject(vendorId, body?.reason);
  }
}
