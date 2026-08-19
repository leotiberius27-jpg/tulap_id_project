import Link from 'next/link';
import { apiFetch } from '@/lib/api';
import { StatusBadge } from '@/components/status-badge';
import { Task, TaskListResponse, TaskStatus } from '@/lib/types';

const FILTERS: { value: TaskStatus | 'ALL'; label: string }[] = [
  { value: 'PENDING_VERIFICATION', label: 'Menunggu Verifikasi' },
  { value: 'VERIFIED', label: 'Terverifikasi' },
  { value: 'REVISION_NEEDED', label: 'Perlu Diperbaiki' },
  { value: 'REJECTED', label: 'Ditolak' },
  { value: 'COMPLETED', label: 'Selesai' },
  { value: 'ALL', label: 'Semua' },
];

const rupiah = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  minimumFractionDigits: 0,
});

export default async function TasksPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const { status } = await searchParams;
  const activeFilter = (status as TaskStatus | 'ALL' | undefined) ?? 'PENDING_VERIFICATION';

  const query = activeFilter === 'ALL' ? '' : `?status=${activeFilter}`;
  const { items } = await apiFetch<TaskListResponse>(`/tasks${query}`);

  return (
    <div>
      <h1 className="text-page-title text-text-primary">Antrean Tugas</h1>
      <p className="mt-1 text-body text-text-secondary">
        Tinjau bukti lapangan dan verifikasi tugas pegawai.
      </p>

      <div className="mt-6 flex flex-wrap gap-2">
        {FILTERS.map((f) => (
          <Link
            key={f.value}
            href={`/tasks?status=${f.value}`}
            className={`rounded-button px-3 py-1.5 text-small font-medium transition ${
              activeFilter === f.value
                ? 'bg-primary text-white'
                : 'bg-surface text-text-secondary hover:bg-background'
            }`}
          >
            {f.label}
          </Link>
        ))}
      </div>

      <div className="mt-6 flex flex-col gap-3">
        {items.length === 0 && (
          <div className="rounded-card bg-surface p-8 text-center shadow-card">
            <p className="text-body text-text-secondary">Tidak ada tugas pada status ini.</p>
          </div>
        )}

        {items.map((task: Task) => (
          <Link
            key={task.id}
            href={`/tasks/${task.id}`}
            className="flex items-center justify-between rounded-card bg-surface p-5 shadow-card transition hover:shadow-dropdown"
          >
            <div>
              <p className="text-small text-text-secondary">{task.taskCode}</p>
              <p className="text-body font-semibold text-text-primary">{task.taskName}</p>
              <p className="mt-1 text-small text-text-secondary">
                {task.assignee.fullName} · {task.destination}
              </p>
            </div>
            <div className="flex flex-col items-end gap-2">
              <StatusBadge status={task.status} />
              <p className="text-small text-text-secondary">
                {rupiah.format(Number(task.budgetAmount))}
              </p>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
