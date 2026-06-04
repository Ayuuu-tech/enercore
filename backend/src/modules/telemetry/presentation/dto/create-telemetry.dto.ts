import { IsNotEmpty, IsNumber, IsUUID } from 'class-validator';

export class CreateTelemetryDto {
  @IsUUID()
  @IsNotEmpty()
  panelId: string;

  @IsNumber()
  @IsNotEmpty()
  voltage: number;

  @IsNumber()
  @IsNotEmpty()
  current: number;

  @IsNumber()
  @IsNotEmpty()
  temperature: number;

  @IsNumber()
  @IsNotEmpty()
  generation: number;
}
