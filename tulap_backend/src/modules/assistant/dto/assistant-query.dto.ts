import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export enum AssistantContextEntityType {
  ACTIVITY = 'ACTIVITY',
  TRAVEL = 'TRAVEL',
  RECEIPT = 'RECEIPT',
  LPJ = 'LPJ',
  EVIDENCE = 'EVIDENCE',
  REPORT = 'REPORT',
}

export class AssistantQueryDto {
  @IsString()
  @MaxLength(500)
  query: string;

  @IsOptional()
  @IsEnum(AssistantContextEntityType)
  contextEntityType?: AssistantContextEntityType;

  @IsOptional()
  @IsString()
  contextEntityId?: string;

  @IsOptional()
  @IsString()
  conversationSessionId?: string;
}
