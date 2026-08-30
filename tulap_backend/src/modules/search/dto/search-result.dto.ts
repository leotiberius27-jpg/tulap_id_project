import { SearchEntityTypeEnum } from './search-query.dto';

export class SearchResultItemDto {
  entityId: string;
  entityType: SearchEntityTypeEnum;
  title: string;
  subtitle?: string | null;
  date: string; // ISO8601
  location?: string | null;
  thumbnailUrl?: string | null;
  matchedField?: string | null;
  matchedText?: string | null;
  relevanceScore: number;
  syncStatus: string;
  parentId?: string | null;
  metadata?: Record<string, any> | null;
}

export class SearchResponseDto {
  items: SearchResultItemDto[];
  totalCount: number;
  nextCursor?: string | null;
  hasMore: boolean;
  query: string;
}
