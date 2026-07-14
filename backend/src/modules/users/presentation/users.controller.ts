import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Put,
  Delete,
  UseGuards,
  ForbiddenException,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { extname, join } from 'path';
import { v4 as uuid } from 'uuid';
import { UsersService } from '../application/users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserEntity } from '../domain/user.entity';
import { Role } from '@prisma/client';
import { BlobStorageService } from '../../../common/storage/blob-storage.service';

@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly storage: BlobStorageService,
  ) {}

  @Get('me')
  async getProfile(@CurrentUser() user: UserEntity) {
    const fullUser = await this.usersService.findById(user.id);
    delete fullUser.password;
    return fullUser;
  }

  @Get()
  @Roles(Role.ADMIN)
  async findAll() {
    const users = await this.usersService.findAll();
    return users.map(user => {
      delete user.password;
      return user;
    });
  }

  @Get(':id')
  async findOne(@Param('id') id: string, @CurrentUser() currentUser: UserEntity) {
    if (currentUser.role !== Role.ADMIN && currentUser.id !== id) {
      throw new ForbiddenException('You do not have permission to access this profile');
    }
    const user = await this.usersService.findById(id);
    delete user.password;
    return user;
  }

  @Put(':id')
  async update(
    @Param('id') id: string,
    @Body() updateUserDto: UpdateUserDto,
    @CurrentUser() currentUser: UserEntity,
  ) {
    if (currentUser.role !== Role.ADMIN && currentUser.id !== id) {
      throw new ForbiddenException('You do not have permission to update this profile');
    }
    const user = await this.usersService.update(id, updateUserDto);
    delete user.password;
    return user;
  }

  @Post(':id/avatar')
  @UseInterceptors(
    FileInterceptor('avatar', {
      // Held in memory, then written to blob storage. The App Service disk is
      // wiped by every redeploy, which used to take users' photos with it.
      storage: memoryStorage(),
      fileFilter: (_req: Express.Request, file: Express.Multer.File, cb: (error: Error | null, acceptFile: boolean) => void) => {
        if (!file.mimetype.match(/^image\//)) {
          cb(new BadRequestException('Only image files are allowed'), false);
          return;
        }
        cb(null, true);
      },
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async uploadAvatar(
    @Param('id') id: string,
    @UploadedFile() file: Express.Multer.File,
    @CurrentUser() currentUser: UserEntity,
  ) {
    if (currentUser.role !== Role.ADMIN && currentUser.id !== id) {
      throw new ForbiddenException('You do not have permission to update this profile');
    }
    if (!file) {
      throw new BadRequestException('Avatar file is required');
    }
    const ext = extname(file.originalname) || '.jpg';
    const avatarUrl = await this.storage.uploadPublic(
      `${id}/${uuid()}${ext}`,
      file.buffer,
      file.mimetype,
    );
    const user = await this.usersService.update(id, { avatarUrl });
    delete user.password;
    return user;
  }

  @Delete(':id')
  @Roles(Role.ADMIN)
  async remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}
