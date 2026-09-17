import Link from 'next/link';
import { apiFetch } from '@/lib/api';
import { Task, TaskListResponse, TaskStatus } from '@/lib/types';
import { TaskCard } from '@/components/task-card';
import { TopHeader } from '@/components/top-header';
import { getSession } from '@/lib/session';
import { ClipboardList, PlusCircle, Filter } from 'lucide-react';

const FILTERS: { value: TaskStatus | 'ALL'; label: string }[] = [
  { value: 'ALL', label: 'Semua Tugas' },
  { value: 'PENDING_VERIFICATION', label: 'Menunggu Review' },
  { value: 'ONGOING', label: 'Dalam Proses' },
  { value: 'REVISION_NEEDED', label: 'Perlu Revisi' },
  { value: 'VERIFIED', label: 'Terverifikasi' },
  { value: 'COMPLETED', label: 'Selesai' },
];

export default async function TasksPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string; q?: string }>;
}) {
  const session = await getSession();
  const { status, q } = await searchParams;
  const activeFilter = (status as TaskStatus | 'ALL' | undefined) ?? 'ALL';

  const queryParams = new URLSearchParams();
  if (activeFilter !== 'ALL') {
    queryParams.set('status', activeFilter);
  }
  if (q) {
    queryParams.set('search', q);
  }

  const queryString = queryParams.toString() ? `?${queryParams.toString()}` : '';
  const { items } = await apiFetch<TaskListResponse>(`/tasks${queryString}`);

  return (
    <div className="space-y-6">
      {/* Top Header Bar with Date, Search, Filter & Notifications */}
      <TopHeader userRole={session?.user?.role} />

      {/* Page Title & Filter Tabs Row matching reference */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-primary tracking-tight flex items-center gap-2.5">
            <span>Antrean Tugas Lapangan</span>
            <span className="text-xs px-2.5 py-0.5 rounded-full bg-primary/10 text-primary font-semibold">
              {items.length} Tugas
            </span>
          </h1>
          <p className="text-small text-text-secondary mt-0.5">
            Tinjau bukti foto geotag, nota pengeluaran, dan verifikasi LPJ lapangan.
          </p>
        </div>

        {/* Filter Pills matching reference */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 max-w-full">
          {FILTERS.map((f) => {
            const isActive = activeFilter === f.value;
            return (
              <Link
                key={f.value}
                href={`/tasks?status=${f.value}${q ? `&q=${encodeURIComponent(q)}` : ''}`}
                className={`px-3.5 py-1.5 rounded-button text-xs font-semibold whitespace-nowrap transition-all ${
                  isActive
                    ? 'bg-primary text-white shadow-sm'
                    : 'bg-surface text-text-secondary hover:text-text-primary hover:bg-background border border-border/70'
                }`}
              >
                {f.label}
              </Link>
            );
          })}
        </div>
      </div>

      {/* Grid of Task Cards matching Bitepoint reference 3-column layout */}
      {items.length === 0 ? (
        <div className="rounded-card bg-surface p-12 text-center border border-border shadow-card flex flex-col items-center justify-center">
          <div className="w-14 h-14 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mb-3">
            <ClipboardList className="w-7 h-7" />
          </div>
          <h3 className="text-body font-semibold text-text-primary">Tidak Ada Tugas</h3>
          <p className="text-small text-text-secondary mt-1 max-w-md">
            Belum ada penugasan lapangan yang sesuai dengan filter atau kata kunci pencarian saat ini.
          </p>
          {(session?.user?.role === 'ADMIN' || session?.user?.role === 'SUPER_ADMIN') && (
            <Link
              href="/tasks/new"
              className="mt-5 inline-flex items-center gap-2 px-4 py-2 bg-primary hover:bg-primary-hover text-white text-small font-medium rounded-button shadow-sm transition"
            >
              <PlusCircle className="w-4 h-4" />
              <span>Buat Penugasan Baru</span>
            </Link>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {items.map((task: Task, index: number) => (
            <TaskCard key={task.id} task={task} index={index} />
          ))}
        </div>
      )}
    </div>
  );
}
