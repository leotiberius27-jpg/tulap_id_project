import { TaskStatus } from '@/lib/types';

const STATUS_CONFIG: Record<TaskStatus, { label: string; className: string }> = {
  DRAFT: { label: 'Draft', className: 'bg-background text-text-secondary' },
  ONGOING: { label: 'Sedang Berjalan', className: 'bg-warning-soft text-warning' },
  PENDING_VERIFICATION: { label: 'Menunggu Verifikasi', className: 'bg-warning-soft text-warning' },
  REVISION_NEEDED: { label: 'Perlu Diperbaiki', className: 'bg-danger-soft text-danger' },
  VERIFIED: { label: 'Terverifikasi', className: 'bg-success-soft text-success' },
  REJECTED: { label: 'Ditolak', className: 'bg-danger-soft text-danger' },
  COMPLETED: { label: 'Selesai', className: 'bg-success-soft text-success' },
};

export function StatusBadge({ status }: { status: TaskStatus }) {
  const config = STATUS_CONFIG[status];
  return (
    <span
      className={`inline-block rounded-small px-2.5 py-1 text-small font-semibold ${config.className}`}
    >
      {config.label}
    </span>
  );
}
