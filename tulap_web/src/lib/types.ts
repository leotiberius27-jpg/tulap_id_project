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
  revisionNotes: RevisionNote[];
};

export type RevisionNote = {
  id: string;
  taskId: string;
  actorId: string;
  note: string;
  status: TaskStatus;
  createdAt: string;
  actor: { id: string; fullName: string };
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

export type RoleName = 'PEGAWAI' | 'VERIFIKATOR' | 'ADMIN' | 'SUPER_ADMIN';

export type Employee = {
  id: string;
  nip: string | null;
  fullName: string;
  email: string;
  phoneNumber: string | null;
  instansiName: string | null;
  unitKerja: string | null;
  isActive: boolean;
  lastLoginAt: string | null;
  createdAt: string;
  updatedAt: string;
  role: { id: string; name: RoleName };
};

export type EmployeeListResponse = {
  items: Employee[];
  meta: { page: number; pageSize: number; total: number; totalPages: number };
};

export type NotificationType =
  | 'TASK_ASSIGNED'
  | 'REVISION_NEEDED'
  | 'TASK_APPROVED'
  | 'TASK_REJECTED'
  | 'LPJ_READY';

export type AppNotification = {
  id: string;
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  relatedTaskId: string | null;
  isRead: boolean;
  createdAt: string;
};

export type NotificationListResponse = {
  items: AppNotification[];
  meta: {
    page: number;
    pageSize: number;
    total: number;
    totalPages: number;
    unreadCount: number;
  };
};
