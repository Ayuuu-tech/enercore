import { Module } from '@nestjs/common';
import { PlantsService } from './application/plants.service';
import { PlantsController } from './presentation/plants.controller';
import { PrismaPlantRepository } from './infrastructure/prisma-plant.repository';
import { PrismaModule } from '../../common/prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [PlantsController],
  providers: [
    PlantsService,
    {
      provide: 'IPlantRepository',
      useClass: PrismaPlantRepository,
    },
  ],
  exports: [PlantsService, 'IPlantRepository'],
})
export class PlantsModule {}
