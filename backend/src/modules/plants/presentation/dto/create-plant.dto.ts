import { IsNotEmpty, IsNumber, IsString, Min } from 'class-validator';

export class CreatePlantDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  location: string;

  @IsNumber()
  @Min(0)
  @IsNotEmpty()
  peakCapacity: number;
}
