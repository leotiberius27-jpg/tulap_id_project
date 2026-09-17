import { redirect } from 'next/navigation';
import { getSession } from '@/lib/session';
import { NewEmployeeForm } from '@/components/new-employee-form';

export default async function NewEmployeePage() {
  const session = await getSession();
  if (!session || (session.user.role !== 'ADMIN' && session.user.role !== 'SUPER_ADMIN')) {
    redirect('/employees');
  }

  return (
    <div>
      <h1 className="text-page-title text-text-primary">Tambah Pegawai</h1>
      <p className="mt-1 text-body text-text-secondary">
        Daftarkan akun baru untuk petugas, verifikator, atau admin instansi.
      </p>

      <div className="mt-6 max-w-lg">
        <NewEmployeeForm canAssignSuperAdmin={session.user.role === 'SUPER_ADMIN'} />
      </div>
    </div>
  );
}
