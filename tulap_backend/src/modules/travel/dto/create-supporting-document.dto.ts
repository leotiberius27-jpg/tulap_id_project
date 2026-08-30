import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateSupportingDocumentDto {
  @IsNotEmpty()
  @IsString()
  id: string;

  @IsNotEmpty()
  @IsString()
  travelMissionId: string;

  @IsOptional()
  @IsString()
  activityId?: string;

  @IsNotEmpty()
  @IsString()
  documentType: string;

  @IsNotEmpty()
  @IsString()
  title: string;

  @IsNotEmpty()
  @IsString()
  sha256: string;
}
