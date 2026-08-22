import Image from 'next/image';
import Link from 'next/link';
import { apiFetch } from '@/lib/api';
import { getSession } from '@/lib/session';
import { StatusBadge } from '@/components/status-badge';
import { VerificationActions } from '@/components/verification-actions';
import { GenerateLpjButton } from '@/components/generate-lpj-button';
import { TopHeader } from '@/components/top-header';
import { ChecklistItem, Task, TaskEvidence } from '@/lib/types';
import {
  ArrowLeft,
  Calendar,
  MapPin,
  User,
  Building2,
  Receipt,
  Camera,
  CheckSquare,
  ShieldCheck,
  AlertTriangle,
} from 'lucide-react';

const rupiah = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  minimumFractionDigits: 0,
});

const dateFormatter = new Intl.DateTimeFormat('id-ID', {
  day: '2-digit',
  month: 'long',
  year: 'numeric',
});

const dateTimeFormatter = new Intl.DateTimeFormat('id-ID', {
  day: '2-digit',
  month: 'short',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
});

const VERIFIER_ROLES = ['VERIFIKATOR', 'SUPER_ADMIN'];
const LPJ_ROLES = ['VERIFIKATOR', 'ADMIN', 'SUPER_ADMIN'];

export default async function TaskDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const session = await getSession();

  const [task, checklistItems, evidence] = await Promise.all([
    apiFetch<Task>(`/tasks/${id}`),
    apiFetch<ChecklistItem[]>(`/tasks/${id}/checklist`),
    apiFetch<TaskEvidence>(`/tasks/${id}/evidence`),
  ]);

  const canVerify =
    task.status === 'PENDING_VERIFICATION' &&
    session &&
    VERIFIER_ROLES.includes(session.user.role);

  const canGenerateLpj =
    task.status === 'VERIFIED' && session && LPJ_ROLES.includes(session.user.role);

  return (
    <div className="space-y-6">
      <TopHeader userRole={session?.user?.role} />

      {/* Breadcrumb & Navigation */}
      <div>
        <Link
          href="/tasks"
          className="inline-flex items-center gap-1.5 text-xs font-semibold text-text-secondary hover:text-primary transition mb-3"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Kembali ke Antrean Tugas</span>
        </Link>

        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <p className="text-xs font-semibold text-primary uppercase tracking-wider">{task.taskCode}</p>
            <h1 className="text-2xl font-bold text-text-primary tracking-tight mt-0.5">{task.taskName}</h1>
          </div>
          <StatusBadge status={task.status} />
        </div>
      </div>

      {/* Main Details Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left 2 Cols: Info, Checklist, and Evidence */}
        <div className="lg:col-span-2 space-y-6">
          {/* Task Info Card */}
          <div className="bg-surface rounded-card p-6 border border-border shadow-card">
            <h2 className="text-body font-bold text-text-primary mb-4 flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-primary" />
              <span>Detail Penugasan</span>
            </h2>

            <dl className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-small">
              <div className="flex items-start gap-3">
                <User className="w-4 h-4 text-text-secondary mt-0.5 shrink-0" />
                <div>
                  <dt className="text-xs text-text-secondary">Petugas Lapangan</dt>
                  <dd className="font-semibold text-text-primary">{task.assignee.fullName}</dd>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Building2 className="w-4 h-4 text-text-secondary mt-0.5 shrink-0" />
                <div>
                  <dt className="text-xs text-text-secondary">Instansi / Unit Kerja</dt>
                  <dd className="font-semibold text-text-primary">{task.assignee.instansiName}</dd>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <MapPin className="w-4 h-4 text-text-secondary mt-0.5 shrink-0" />
                <div>
                  <dt className="text-xs text-text-secondary">Lokasi Tujuan</dt>
                  <dd className="font-semibold text-text-primary">{task.destination}</dd>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <Calendar className="w-4 h-4 text-text-secondary mt-0.5 shrink-0" />
                <div>
                  <dt className="text-xs text-text-secondary">Periode Pelaksanaan</dt>
                  <dd className="font-semibold text-text-primary">
                    {dateFormatter.format(new Date(task.startDate))} - {dateFormatter.format(new Date(task.endDate))}
                  </dd>
                </div>
              </div>

              {task.description && (
                <div className="col-span-full pt-2 border-t border-border/60">
                  <dt className="text-xs text-text-secondary mb-1">Deskripsi Tugas</dt>
                  <dd className="text-text-primary text-xs leading-relaxed bg-background/60 p-3 rounded-button">
                    {task.description}
                  </dd>
                </div>
              )}
            </dl>
          </div>

          {/* Checklist Card */}
          <div className="bg-surface rounded-card p-6 border border-border shadow-card">
            <h2 className="text-body font-bold text-text-primary mb-4 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <CheckSquare className="w-5 h-5 text-primary" />
                <span>Checklist Verifikasi Lapangan</span>
              </div>
              <span className="text-xs px-2.5 py-0.5 rounded-full bg-primary/10 text-primary font-semibold">
                {checklistItems.filter((c) => c.isCompleted).length} / {checklistItems.length} Selesai
              </span>
            </h2>

            <ul className="space-y-2.5">
              {checklistItems.map((item) => (
                <li
                  key={item.id}
                  className="flex items-center justify-between p-3 rounded-button border border-border/60 bg-background/30 text-small"
                >
                  <div className="flex items-center gap-3">
                    <span
                      className={`flex h-5 w-5 items-center justify-center rounded-full text-xs font-bold ${
                        item.isCompleted
                          ? 'bg-emerald-500 text-white'
                          : 'bg-border text-text-secondary'
                      }`}
                    >
                      {item.isCompleted ? '✓' : ''}
                    </span>
                    <span className={item.isCompleted ? 'font-medium text-text-primary' : 'text-text-secondary'}>
                      {item.label}
                    </span>
                  </div>
                  {item.isMandatory && (
                    <span className="text-[11px] px-2 py-0.5 rounded-full bg-rose-50 text-rose-600 font-semibold border border-rose-200">
                      Wajib
                    </span>
                  )}
                </li>
              ))}
            </ul>
          </div>

          {/* Geotag Photos Card */}
          <div className="bg-surface rounded-card p-6 border border-border shadow-card">
            <h2 className="text-body font-bold text-text-primary mb-4 flex items-center gap-2">
              <Camera className="w-5 h-5 text-primary" />
              <span>Bukti Foto Geotag Lapangan ({evidence.photos.length})</span>
            </h2>

            {evidence.photos.length === 0 ? (
              <p className="text-small text-text-secondary text-center py-6">Belum ada foto yang diunggah.</p>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {evidence.photos.map((photo) => (
                  <div
                    key={photo.id}
                    className="overflow-hidden rounded-button border border-border bg-background"
                  >
                    <div className="relative h-48 w-full bg-slate-100">
                      <Image
                        src={photo.photoUrl}
                        alt={photo.caption ?? 'Bukti Lapangan'}
                        fill
                        className="object-cover"
                        unoptimized
                      />
                    </div>
                    <div className="p-3 text-xs space-y-1">
                      {photo.caption && <p className="font-semibold text-text-primary">{photo.caption}</p>}
                      <p className="text-text-secondary flex items-center gap-1">
                        <MapPin className="w-3 h-3 text-primary shrink-0" />
                        <span className="truncate">{photo.address ?? `${photo.latitude}, ${photo.longitude}`}</span>
                      </p>
                      <p className="text-[11px] text-text-secondary">
                        {dateTimeFormatter.format(new Date(photo.serverTimestamp))}
                      </p>
                      {(photo.isMockLocationFlag || photo.isRootedDeviceFlag) && (
                        <div className="flex items-center gap-1 text-rose-600 font-semibold pt-1">
                          <AlertTriangle className="w-3.5 h-3.5" />
                          <span>Peringatan Keamanan Lokasi</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Expense Notes Card */}
          <div className="bg-surface rounded-card p-6 border border-border shadow-card">
            <h2 className="text-body font-bold text-text-primary mb-4 flex items-center gap-2">
              <Receipt className="w-5 h-5 text-primary" />
              <span>Bukti Nota Pengeluaran ({evidence.expenseNotes.length})</span>
            </h2>

            {evidence.expenseNotes.length === 0 ? (
              <p className="text-small text-text-secondary text-center py-6">Belum ada nota yang diunggah.</p>
            ) : (
              <div className="space-y-3">
                {evidence.expenseNotes.map((note) => (
                  <div
                    key={note.id}
                    className="flex items-center justify-between p-3.5 rounded-button border border-border bg-background/30 text-small"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-lg bg-amber-500/10 text-amber-600 flex items-center justify-center font-bold text-xs">
                        {note.category.slice(0, 3)}
                      </div>
                      <div>
                        <p className="font-semibold text-text-primary">{note.vendorName}</p>
                        <p className="text-xs text-text-secondary">{note.category} · {note.transactionDate}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="font-bold text-text-primary">{rupiah.format(Number(note.totalAmount))}</p>
                      <span className="text-[11px] font-semibold text-emerald-600">
                        {note.verificationStatus}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right Col: Summary & Action Card */}
        <div className="space-y-6">
          {/* Budget & Verification Card */}
          <div className="bg-surface rounded-card p-6 border border-border shadow-card sticky top-6">
            <h2 className="text-body font-bold text-text-primary mb-4">Ringkasan Verifikasi</h2>

            <div className="space-y-3 pb-4 border-b border-border text-small">
              <div className="flex justify-between">
                <span className="text-text-secondary">Pagu Anggaran</span>
                <span className="font-semibold text-text-primary">{rupiah.format(Number(task.budgetAmount))}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-text-secondary">Realisasi Lapangan</span>
                <span className="font-bold text-primary">{rupiah.format(Number(task.realizedAmount))}</span>
              </div>
            </div>

            {/* Verification Actions or LPJ */}
            <div className="mt-5 space-y-3">
              {canVerify && <VerificationActions taskId={task.id} />}
              {canGenerateLpj && <GenerateLpjButton taskId={task.id} taskCode={task.taskCode} />}
              {!canVerify && !canGenerateLpj && (
                <div className="p-3 bg-background rounded-button text-xs text-text-secondary text-center">
                  Status: <strong className="text-text-primary">{task.status}</strong>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
