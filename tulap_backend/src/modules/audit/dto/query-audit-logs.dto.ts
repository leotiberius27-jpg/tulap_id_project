import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, IsUUID, Max, Min } from 'class-validator';

export class QueryAuditLogsDto {
  @IsInt()
  @Min(1)
  @IsOptional()
  @Type(() => Number)
  page?: number = 1;

  @IsInt()
  @Min(1)
  @Max(100)
  @IsOptional()
  @Type(() => Number)
  pageSize?: number = 50;

  @IsString()
  @IsOptional()
  entity?: string;

  @IsUUID()
  @IsOptional()
  entityId?: string;

  @IsUUID()
  @IsOptional()
  actorId?: string;
}
