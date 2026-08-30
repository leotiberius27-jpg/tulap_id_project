import { IsOptional, IsString, IsArray, IsInt, Min, Max, IsEnum, IsDateString } from 'class-validator';
import { Type, Transform } from 'class-transformer';

export enum SearchEntityTypeEnum {
  ACTIVITY = 'ACTIVITY',
  TRAVEL = 'TRAVEL',
  EVIDENCE = 'EVIDENCE',
  RECEIPT = 'RECEIPT',
  EXPENSE = 'EXPENSE',
  REPORT = 'REPORT',
  DOCUMENT = 'DOCUMENT',
  LPJ = 'LPJ',
}

export enum SearchSortEnum {
  RELEVANCE = 'relevance',
  NEWEST = 'newest',
  OLDEST = 'oldest',
}

export class SearchQueryDto {
  @IsOptional()
  @IsString()
  q?: string;

  @IsOptional()
  @Transform(({ value }) => {
    if (typeof value === 'string') {
      return value.split(',').map((v) => v.trim().toUpperCase());
    }
    if (Array.isArray(value)) {
      return value.map((v) => String(v).trim().toUpperCase());
    }
    return value;
  })
  @IsArray()
  @IsEnum(SearchEntityTypeEnum, { each: true })
  entityTypes?: SearchEntityTypeEnum[];

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
  location?: string;

  @IsOptional()
  @IsString()
  status?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsEnum(SearchSortEnum)
  sort?: SearchSortEnum = SearchSortEnum.RELEVANCE;

  @IsOptional()
  @IsString()
  cursor?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}
