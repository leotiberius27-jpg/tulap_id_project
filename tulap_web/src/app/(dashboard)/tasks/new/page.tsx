import { redirect } from 'next/navigation';
import { apiFetch } from '@/lib/api';
import { getSession } from '@/lib/session';
import { EmployeeListResponse } from '@/lib/types';
import { CreateTaskForm } from '@/components/create-task-form';

/// Halaman ini hanya untuk ADMIN/SUPER_ADMIN (Bagian 26 Permission
/// Model: "Buat penugasan" bukan hak Verifikator/Petugas). Backend
/// sudah menegakkan ini di `POST /tasks` (@Roles ADMIN, SUPER_ADMIN),
/// redirect di sini murni agar Verifikator tidak melihat form yang
/// akan ditolak.
export default async function NewTaskPage() {
  const session = await getSession();
  if (!session || (session.user.role !== 'ADMIN' && session.user.role !== 'SUPER_ADMIN')) {
    redirect('/tasks');
  }

  const { items: employees } = await apiFetch<EmployeeListResponse>(
    '/users?roleName=PEGAWAI&pageSize=100',
  );

  return (
    <div>
      <h1 className="text-page-title text-text-primary">Buat Tugas</h1>
      <p className="mt-1 text-body text-text-secondary">
        Tentukan petugas, lokasi, jadwal, dan checklist bukti wajib untuk penugasan baru.
      </p>

      <div className="mt-6">
        <CreateTaskForm employees={employees} />
      </div>
    </div>
  );
}
