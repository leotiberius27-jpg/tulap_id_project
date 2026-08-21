import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiFetch } from '@/lib/api';
import { getSession } from '@/lib/session';
import { EmployeeListResponse, RoleName } from '@/lib/types';
import { EmployeeActions } from '@/components/employee-actions';

const ROLE_LABEL: Record<RoleName, string> = {
  PEGAWAI: 'Petugas',
  VERIFIKATOR: 'Verifikator',
  ADMIN: 'Admin',
  SUPER_ADMIN: 'Super Admin',
};

const ROLE_FILTERS: { value: RoleName | 'ALL'; label: string }[] = [
  { value: 'ALL', label: 'Semua' },
  { value: 'PEGAWAI', label: 'Petugas' },
  { value: 'VERIFIKATOR', label: 'Verifikator' },
  { value: 'ADMIN', label: 'Admin' },
  { value: 'SUPER_ADMIN', label: 'Super Admin' },
];

export default async function EmployeesPage({
  searchParams,
}: {
  searchParams: Promise<{ role?: string; search?: string }>;
}) {
  const session = await getSession();
  if (
    !session ||
    (session.user.role !== 'ADMIN' &&
      session.user.role !== 'SUPER_ADMIN' &&
      session.user.role !== 'VERIFIKATOR')
  ) {
    redirect('/tasks');
  }

  const canManage = session.user.role === 'ADMIN' || session.user.role === 'SUPER_ADMIN';

  const { role, search } = await searchParams;
  const activeRole = (role as RoleName | 'ALL' | undefined) ?? 'ALL';

  const query = new URLSearchParams({ pageSize: '100' });
  if (activeRole !== 'ALL') query.set('roleName', activeRole);
  if (search) query.set('search', search);

  const { items } = await apiFetch<EmployeeListResponse>(`/users?${query.toString()}`);

  return (
    <div>
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-page-title text-text-primary">Pegawai</h1>
          <p className="mt-1 text-body text-text-secondary">
            Kelola akun petugas, verifikator, dan admin instansi.
          </p>
        </div>
        {canManage && (
          <Link
            href="/employees/new"
            className="rounded-button bg-primary px-4 py-2.5 text-body font-semibold text-white transition hover:bg-primary-hover"
          >
            + Tambah Pegawai
          </Link>
        )}
      </div>

      <form className="mt-6 flex flex-wrap items-center gap-3" action="/employees">
        <input
          name="search"
          defaultValue={search ?? ''}
          placeholder="Cari nama, email, atau NIP..."
          className="w-64 rounded-button border border-border px-3 py-2 text-small outline-none focus:border-primary"
        />
        <button
          type="submit"
          className="rounded-button bg-background px-3 py-2 text-small font-medium text-text-secondary hover:bg-border"
        >
          Cari
        </button>
      </form>

      <div className="mt-4 flex flex-wrap gap-2">
        {ROLE_FILTERS.map((f) => (
          <Link
            key={f.value}
            href={`/employees?role=${f.value}${search ? `&search=${search}` : ''}`}
            className={`rounded-button px-3 py-1.5 text-small font-medium transition ${
              activeRole === f.value
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
            <p className="text-body text-text-secondary">Tidak ada pegawai ditemukan.</p>
          </div>
        )}

        {items.map((employee) => (
          <div
            key={employee.id}
            className="flex items-center justify-between rounded-card bg-surface p-5 shadow-card"
          >
            <div>
              <p className="text-body font-semibold text-text-primary">{employee.fullName}</p>
              <p className="text-small text-text-secondary">
                {employee.email}
                {employee.nip ? ` · NIP ${employee.nip}` : ''}
              </p>
              <p className="mt-1 text-small text-text-secondary">
                {employee.instansiName ?? 'Tanpa instansi'}
                {employee.unitKerja ? ` · ${employee.unitKerja}` : ''}
              </p>
            </div>
            <div className="flex items-center gap-4">
              <div className="flex flex-col items-end gap-1">
                <span className="rounded-small bg-background px-2 py-1 text-small font-medium text-text-primary">
                  {ROLE_LABEL[employee.role.name]}
                </span>
                <span
                  className={`text-small ${employee.isActive ? 'text-success' : 'text-danger'}`}
                >
                  {employee.isActive ? 'Aktif' : 'Nonaktif'}
                </span>
              </div>
              {canManage && <EmployeeActions id={employee.id} isActive={employee.isActive} />}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
