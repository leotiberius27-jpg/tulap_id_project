import {
  IsNotEmpty,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateLpjPackageDto {
  @IsNotEmpty()
  @IsString()
  id: string;

  @IsNotEmpty()
  @IsString()
  travelMissionId: string;

  @IsNotEmpty()
  @IsString()
  packageCode: string;

  @IsNotEmpty()
  @IsNumber()
  versionNumber: number;

  @IsNotEmpty()
  @IsString()
  title: string;

  @IsNotEmpty()
  @IsString()
  packageSha256: string;

  @IsNotEmpty()
  @IsNumber()
  completenessScore: number;

  @IsNotEmpty()
  @IsNumber()
  totalActualExpense: number;

  @IsOptional()
  @IsNumber()
  activityCount?: number;

  @IsOptional()
  @IsNumber()
  evidenceCount?: number;

  @IsOptional()
  @IsNumber()
  receiptCount?: number;

  @IsOptional()
  @IsNumber()
  documentCount?: number;

  @IsNotEmpty()
  @IsObject()
  contentSnapshot: Record<string, any>;

  @IsOptional()
  @IsString()
  status?: string;
}
