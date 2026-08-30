import {
  IsArray,
  IsDateString,
  IsNotEmpty,
  IsObject,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateTravelMissionDto {
  @IsNotEmpty()
  @IsString()
  id: string;

  @IsNotEmpty()
  @IsString()
  displayId: string;

  @IsNotEmpty()
  @IsString()
  assignmentLetterNumber: string;

  @IsNotEmpty()
  @IsDateString()
  assignmentLetterDate: string;

  @IsNotEmpty()
  @IsString()
  title: string;

  @IsNotEmpty()
  @IsString()
  purpose: string;

  @IsNotEmpty()
  @IsString()
  origin: string;

  @IsNotEmpty()
  @IsString()
  destination: string;

  @IsOptional()
  @IsArray()
  destinations?: string[];

  @IsNotEmpty()
  @IsDateString()
  departureDate: string;

  @IsNotEmpty()
  @IsDateString()
  returnDate: string;

  @IsNotEmpty()
  @IsString()
  transportMode: string;

  @IsOptional()
  @IsString()
  transportDetails?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsObject()
  budgetEstimate?: Record<string, any>;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsObject()
  personnelSnapshot?: Record<string, any>;
}
