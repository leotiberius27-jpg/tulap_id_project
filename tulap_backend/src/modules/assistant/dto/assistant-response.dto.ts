export enum AssistantIntentEnum {
  SEARCH = 'SEARCH',
  COUNT = 'COUNT',
  TOTAL = 'TOTAL',
  SUMMARY = 'SUMMARY',
  STATUS = 'STATUS',
  COMPLETENESS = 'COMPLETENESS',
  NAVIGATION = 'NAVIGATION',
  REPORT_ASSISTANCE = 'REPORT_ASSISTANCE',
  DOCUMENT_ASSISTANCE = 'DOCUMENT_ASSISTANCE',
  WRITE_ACTION = 'WRITE_ACTION',
  DESTRUCTIVE_ACTION = 'DESTRUCTIVE_ACTION',
  UNKNOWN = 'UNKNOWN',
}

export class AssistantSourceDto {
  id: string;
  title: string;
  entityType: string;
  referenceId: string;
}

export class AssistantCardDto {
  id: string;
  entityType: string;
  title: string;
  subtitle?: string;
  date?: string;
  location?: string;
  amount?: string;
  status?: string;
  badge?: string;
  metadata?: Record<string, any>;
}

export class AssistantActionDto {
  actionType:
    | 'OPEN_ACTIVITY'
    | 'OPEN_TRAVEL'
    | 'OPEN_EVIDENCE'
    | 'OPEN_RECEIPT'
    | 'OPEN_REPORT'
    | 'OPEN_LPJ'
    | 'OPEN_SEARCH'
    | 'PREPARE_REPORT'
    | 'MARK_ACTIVITY_COMPLETE'
    | 'DELETE_CONFIRM';
  label: string;
  entityId?: string;
  payload?: Record<string, any>;
  isDestructive?: boolean;
}

export class AssistantContextDto {
  contextEntityType: string;
  contextEntityId: string;
  contextTitle?: string;
}

export class AssistantResponseDto {
  message: string;
  intent: AssistantIntentEnum;
  sources: AssistantSourceDto[];
  cards: AssistantCardDto[];
  suggestedActions: AssistantActionDto[];
  context?: AssistantContextDto;
  requiresConfirmation?: boolean;
  confirmationAction?: AssistantActionDto;
}
