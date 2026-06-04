import { IsEnum, IsInt, IsNotEmpty, IsOptional, Min } from 'class-validator';
import { PanelStatus } from '@prisma/client';

export class CreatePanelDto {
  @IsInt()
  @Min(0)
  @IsNotEmpty()
  row: number;

  @IsInt()
  @Min(0)
  @IsNotEmpty()
  column: number;

  @IsEnum(PanelStatus)
  @IsOptional()
  status?: PanelStatus;
}
