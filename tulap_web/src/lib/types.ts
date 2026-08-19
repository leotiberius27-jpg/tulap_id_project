export type TaskStatus =
  | 'DRAFT'
  | 'ONGOING'
  | 'PENDING_VERIFICATION'
  | 'REVISION_NEEDED'
  | 'VERIFIED'
  | 'REJECTED'
  | 'COMPLETED';

export type Task = {
  id: string;
  taskCode: string;
  taskName: string;
  destination: string;
  description: string | null;
  startDate: string;
  endDate: string;
  budgetAmount: string;
  realizedAmount: string;
  status: TaskStatus;
  assigneeId: string;
  creatorId: string;
  createdAt: string;
  updatedAt: string;
  assignee: { id: string; fullName: string; email: string; instansiName: string };
  creator: { id: string; fullName: string; email: string };
};

export type ChecklistItem = {
  id: string;
  taskId: string;
  label: string;
  order: number;
  isMandatory: boolean;
  isCompleted: boolean;
  completedAt: string | null;
};

export type GeotagPhoto = {
  id: string;
  taskId: string;
  uploaderId: string;
  photoUrl: string;
  latitude: string;
  longitude: string;
  address: string | null;
  serverTimestamp: string;
  isMockLocationFlag: boolean;
  isRootedDeviceFlag: boolean;
  caption: string | null;
};

export type ExpenseCategory =
  | 'BBM'
  | 'TOL'
  | 'PENGINAPAN'
  | 'RETAIL'
  | 'KONSUMSI'
  | 'TRANSPORTASI_LAIN'
  | 'LAINNYA';

export type ExpenseNote = {
  id: string;
  taskId: string;
  ownerId: string;
  scanUrl: string;
  vendorName: string;
  transactionDate: string;
  totalAmount: string;
  category: ExpenseCategory;
  verificationStatus: 'PENDING' | 'VERIFIED' | 'REJECTED';
};

export type TaskEvidence = {
  photos: GeotagPhoto[];
  expenseNotes: ExpenseNote[];
};

export type TaskListResponse = {
  items: Task[];
  meta: { page: number; pageSize: number; total: number; totalPages: number };
};
