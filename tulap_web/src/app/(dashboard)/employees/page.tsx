import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiFetch } from '@/lib/api';
import { getSession } from '@/lib/session';
import { EmployeeListResponse, RoleName } from '@/lib/types';
import { EmployeeActions } from '@/components/employee-actions';
import { TopHeader } from '@/components/top-header';
import { Users, UserPlus, Shield, Mail, Building2 } from 'lucide-react';

const ROLE_LABEL: Record<RoleName, string> = {
  PEGAWAI: 'Pegawai Lapangan',
  VERIFIKATOR: 'Verifikator',
  ADMIN: 'Admin Instansi',
  SUPER_ADMIN: 'Super Admin',
};

const ROLE_FILTERS: { value: RoleName | 'ALL'; label: string }[] = [
  { value: 'ALL', label: 'Semua Akun' },
  { value: 'PEGAWAI', label: 'Pegawai Lapangan' },
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
    <div className="space-y-6">
      <TopHeader userRole={session?.user?.role} />

      {/* Header section */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-text-primary tracking-tight flex items-center gap-2.5">
            <span>Manajemen Pegawai &amp; Petugas</span>
            <span className="text-xs px-2.5 py-0.5 rounded-full bg-primary/10 text-primary font-semibold">
              {items.length} Pegawai
            </span>
          </h1>
          <p className="text-small text-text-secondary mt-0.5">
            Kelola akun petugas lapangan, hak akses verifikator, dan admin instansi.
          </p>
        </div>

        {canManage && (
          <Link
            href="/employees/new"
            className="inline-flex items-center gap-2 px-4 py-2.5 bg-primary hover:bg-primary-hover text-white text-small font-semibold rounded-button shadow-sm transition"
          >
            <UserPlus className="w-4 h-4" />
            <span>Tambah Pegawai Baru</span>
          </Link>
        )}
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 max-w-full">
        {ROLE_FILTERS.map((f) => {
          const isActive = activeRole === f.value;
          return (
            <Link
              key={f.value}
              href={`/employees?role=${f.value}${search ? `&search=${search}` : ''}`}
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

      {/* Employees Card Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {items.length === 0 && (
          <div className="col-span-full rounded-card bg-surface p-12 text-center border border-border shadow-card flex flex-col items-center justify-center">
            <div className="w-14 h-14 rounded-2xl bg-primary/10 text-primary flex items-center justify-center mb-3">
              <Users className="w-7 h-7" />
            </div>
            <h3 className="text-body font-semibold text-text-primary">Tidak Ada Pegawai</h3>
            <p className="text-small text-text-secondary mt-1">
              Tidak ada data pegawai yang sesuai dengan filter saat ini.
            </p>
          </div>
        )}

        {items.map((employee) => {
          const initials = employee.fullName
            .split(' ')
            .slice(0, 2)
            .map((n) => n[0])
            .join('')
            .toUpperCase();

          return (
            <div
              key={employee.id}
              className="bg-surface rounded-card p-5 border border-border/80 shadow-card hover:shadow-dropdown transition-all flex flex-col justify-between"
            >
              <div>
                <div className="flex items-start justify-between gap-3 mb-3">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-xl bg-primary/10 text-primary font-bold text-xs flex items-center justify-center shrink-0 border border-primary/20">
                      {initials}
                    </div>
                    <div>
                      <h3 className="text-body font-bold text-text-primary line-clamp-1">
                        {employee.fullName}
                      </h3>
                      <p className="text-[11px] text-text-secondary">
                        {employee.nip ? `NIP: ${employee.nip}` : 'ID Terverifikasi'}
                      </p>
                    </div>
                  </div>

                  <span
                    className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold border ${
                      employee.isActive
                        ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                        : 'bg-rose-50 text-rose-700 border-rose-200'
                    }`}
                  >
                    {employee.isActive ? 'Aktif' : 'Nonaktif'}
                  </span>
                </div>

                <div className="space-y-2 text-xs text-text-secondary py-2 border-y border-border/60 mb-4">
                  <div className="flex items-center gap-2">
                    <Mail className="w-3.5 h-3.5 text-text-secondary shrink-0" />
                    <span className="truncate">{employee.email}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Building2 className="w-3.5 h-3.5 text-text-secondary shrink-0" />
                    <span className="truncate">
                      {employee.instansiName ?? 'Pemerintah Daerah'}
                      {employee.unitKerja ? ` · ${employee.unitKerja}` : ''}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Shield className="w-3.5 h-3.5 text-primary shrink-0" />
                    <span className="font-medium text-text-primary">
                      {ROLE_LABEL[employee.role.name]}
                    </span>
                  </div>
                </div>
              </div>

              <div className="pt-2 flex items-center justify-end">
                {canManage && <EmployeeActions id={employee.id} isActive={employee.isActive} />}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
