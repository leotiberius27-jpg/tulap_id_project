import Image from 'next/image';
import { apiFetch } from '@/lib/api';
import { getSession } from '@/lib/session';
import { StatusBadge } from '@/components/status-badge';
import { VerificationActions } from '@/components/verification-actions';
import { GenerateLpjButton } from '@/components/generate-lpj-button';
import { ChecklistItem, Task, TaskEvidence } from '@/lib/types';

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

  const canGenerateLpj = task.status === 'VERIFIED' && session && LPJ_ROLES.includes(session.user.role);

  return (
    <div className="flex flex-col gap-6">
      <div>
        <p className="text-small text-text-secondary">{task.taskCode}</p>
        <div className="mt-1 flex items-center gap-3">
          <h1 className="text-page-title text-text-primary">{task.taskName}</h1>
          <StatusBadge status={task.status} />
        </div>
      </div>

      <div className="rounded-card bg-surface p-5 shadow-card">
        <p className="mb-3 text-small font-semibold text-text-primary">Informasi Tugas</p>
        <dl className="grid grid-cols-2 gap-4 text-small">
          <Field label="Petugas" value={task.assignee.fullName} />
          <Field label="Instansi" value={task.assignee.instansiName} />
          <Field label="Lokasi Tujuan" value={task.destination} />
          <Field
            label="Jadwal"
            value={`${dateFormatter.format(new Date(task.startDate))} - ${dateFormatter.format(new Date(task.endDate))}`}
          />
          <Field label="Anggaran" value={rupiah.format(Number(task.budgetAmount))} />
          {task.description && (
            <Field label="Deskripsi" value={task.description} className="col-span-2" />
          )}
        </dl>
      </div>

      <div className="rounded-card bg-surface p-5 shadow-card">
        <p className="mb-3 text-small font-semibold text-text-primary">
          Checklist ({checklistItems.filter((c) => c.isCompleted).length}/{checklistItems.length})
        </p>
        <ul className="flex flex-col gap-2">
          {checklistItems.map((item) => (
            <li key={item.id} className="flex items-center gap-2 text-small">
              <span
                className={`flex h-5 w-5 items-center justify-center rounded-full text-white ${
                  item.isCompleted ? 'bg-success' : 'bg-border text-text-secondary'
                }`}
              >
                {item.isCompleted ? '✓' : ''}
              </span>
              <span className={item.isCompleted ? 'text-text-primary' : 'text-text-secondary'}>
                {item.label}
              </span>
              {item.isMandatory && (
                <span className="text-small text-text-secondary">(wajib)</span>
              )}
            </li>
          ))}
          {checklistItems.length === 0 && (
            <p className="text-small text-text-secondary">Belum ada item checklist.</p>
          )}
        </ul>
      </div>

      <div className="rounded-card bg-surface p-5 shadow-card">
        <p className="mb-3 text-small font-semibold text-text-primary">
          Bukti Foto Kegiatan ({evidence.photos.length})
        </p>
        {evidence.photos.length === 0 ? (
          <p className="text-small text-text-secondary">Belum ada bukti foto.</p>
        ) : (
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            {evidence.photos.map((photo) => (
              <div key={photo.id} className="overflow-hidden rounded-small border border-border">
                <div className="relative aspect-square bg-background">
                  <Image
                    src={photo.photoUrl}
                    alt={photo.caption ?? 'Bukti foto kegiatan'}
                    fill
                    unoptimized
                    className="object-cover"
                  />
                </div>
                <div className="p-2">
                  <p className="text-small text-text-secondary">
                    {dateTimeFormatter.format(new Date(photo.serverTimestamp))}
                  </p>
                  {(photo.isMockLocationFlag || photo.isRootedDeviceFlag) && (
                    <p className="mt-1 text-small font-semibold text-danger">
                      ⚠ {photo.isMockLocationFlag ? 'Lokasi palsu terdeteksi' : ''}
                      {photo.isMockLocationFlag && photo.isRootedDeviceFlag ? ' · ' : ''}
                      {photo.isRootedDeviceFlag ? 'Perangkat root terdeteksi' : ''}
                    </p>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="rounded-card bg-surface p-5 shadow-card">
        <p className="mb-3 text-small font-semibold text-text-primary">
          Nota Pengeluaran ({evidence.expenseNotes.length})
        </p>
        {evidence.expenseNotes.length === 0 ? (
          <p className="text-small text-text-secondary">Belum ada nota pengeluaran.</p>
        ) : (
          <ul className="flex flex-col gap-2">
            {evidence.expenseNotes.map((note) => (
              <li
                key={note.id}
                className="flex items-center justify-between border-b border-border pb-2 text-small last:border-0"
              >
                <div>
                  <p className="font-medium text-text-primary">{note.vendorName}</p>
                  <p className="text-text-secondary">
                    {dateFormatter.format(new Date(note.transactionDate))} · {note.category}
                  </p>
                </div>
                <p className="font-semibold text-text-primary">
                  {rupiah.format(Number(note.totalAmount))}
                </p>
              </li>
            ))}
          </ul>
        )}
      </div>

      {canVerify && <VerificationActions taskId={task.id} />}
      {canGenerateLpj && <GenerateLpjButton taskId={task.id} taskCode={task.taskCode} />}
    </div>
  );
}

function Field({
  label,
  value,
  className,
}: {
  label: string;
  value: string;
  className?: string;
}) {
  return (
    <div className={className}>
      <dt className="text-text-secondary">{label}</dt>
      <dd className="font-medium text-text-primary">{value}</dd>
    </div>
  );
}
