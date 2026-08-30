export interface DashboardPeriodInfo {
  type: string;
  dateFrom: string;
  dateTo: string;
  label: string;
}

export interface DashboardSummaryDto {
  activityTotal: number;
  activityCompleted: number;
  activityOngoing: number;
  activityCompletionRate: number; // percentage (0.0 to 100.0)

  photoCount: number;
  videoCount: number;
  evidenceTotal: number;

  travelTotal: number;
  travelCompleted: number;
  travelDays: number;

  expenseTotal: number; // Confirmed authoritative IDR sum
  expensePreviousPeriodTotal?: number;

  reportCount: number;
  lpjComplete: number;
  lpjIncomplete: number;
}

export interface ActionRequiredItemDto {
  type: 'lpjIncomplete' | 'pendingSync' | 'receiptNeedsReview' | 'activityIncomplete' | 'integrityIssue';
  title: string;
  subtitle: string;
  count: number;
  severity: 'warning' | 'info' | 'danger';
  filterParams?: Record<string, any>;
}

export interface ActivityTrendPointDto {
  date: string; // YYYY-MM-DD
  label: string; // e.g. "26 Agu"
  count: number;
}

export interface ExpenseCategoryItemDto {
  category: string;
  amount: number;
  percentage: number;
  count: number;
}

export interface TopLocationItemDto {
  location: string;
  count: number;
  latitude?: number;
  longitude?: number;
}

export interface TravelDestinationItemDto {
  destination: string;
  count: number;
}

export interface DashboardResponseDto {
  period: DashboardPeriodInfo;
  summary: DashboardSummaryDto;
  actionRequired: ActionRequiredItemDto[];
  activityTrend: ActivityTrendPointDto[];
  expenseByCategory: ExpenseCategoryItemDto[];
  topLocations: TopLocationItemDto[];
  travelDestinations: TravelDestinationItemDto[];
  insights: string[];
}
