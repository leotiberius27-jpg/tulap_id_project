import { IsOptional, IsString, IsInt, Min, Max, IsDateString, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';

export enum DashboardPeriodEnum {
  TODAY = 'today',
  SEVEN_DAYS = 'sevenDays',
  THIRTY_DAYS = 'thirtyDays',
  THIS_MONTH = 'thisMonth',
  THIS_YEAR = 'thisYear',
  CUSTOM = 'custom',
}

export class DashboardQueryDto {
  @IsOptional()
  @IsEnum(DashboardPeriodEnum)
  period?: DashboardPeriodEnum;

  @IsOptional()
  @IsDateString()
  dateFrom?: string;

  @IsOptional()
  @IsDateString()
  dateTo?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(2000)
  @Max(2100)
  year?: number;

  @IsOptional()
  @IsString()
  scope?: string; // 'personal' | 'team' (default 'personal')
}
