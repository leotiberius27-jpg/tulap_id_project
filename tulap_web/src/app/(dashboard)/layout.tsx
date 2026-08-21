import { redirect } from 'next/navigation';
import Link from 'next/link';
import { getSession } from '@/lib/session';
import { LogoutButton } from '@/components/logout-button';
import { NotificationBell } from '@/components/notification-bell';

const ROLE_LABEL: Record<string, string> = {
  VERIFIKATOR: 'Verifikator',
  ADMIN: 'Admin Instansi',
  SUPER_ADMIN: 'Super Admin',
};

// Penugasan & Pegawai hanya untuk ADMIN/SUPER_ADMIN (Bagian 26 Permission
// Model) - Verifikator hanya perlu Tugas (antrian verifikasi). Backend
// sudah menegakkan RBAC ini di endpoint masing-masing, nav ini murni
// supaya Verifikator tidak melihat tautan yang akan ditolak.
function canManage(role: string) {
  return role === 'ADMIN' || role === 'SUPER_ADMIN';
}

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await getSession();
  if (!session) {
    redirect('/login');
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b border-border bg-surface">
        <div className="mx-auto flex max-w-5xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-8">
            <div>
              <p className="text-section-title font-bold text-primary">Tulap.id</p>
              <p className="text-small text-text-secondary">Dashboard Verifikasi &amp; LPJ</p>
            </div>
            <nav className="flex items-center gap-1">
              <NavLink href="/tasks">Tugas</NavLink>
              {canManage(session.user.role) && (
                <>
                  <NavLink href="/tasks/new">Buat Tugas</NavLink>
                  <NavLink href="/employees">Pegawai</NavLink>
                </>
              )}
            </nav>
          </div>
          <div className="flex items-center gap-3">
            <NotificationBell />
            <div className="text-right">
              <p className="text-small font-semibold text-text-primary">
                {session.user.fullName}
              </p>
              <p className="text-small text-text-secondary">
                {ROLE_LABEL[session.user.role] ?? session.user.role} · {session.user.instansiName}
              </p>
            </div>
            <LogoutButton />
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-5xl px-6 py-8">{children}</main>
    </div>
  );
}

function NavLink({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <Link
      href={href}
      className="rounded-button px-3 py-1.5 text-small font-medium text-text-secondary transition hover:bg-background hover:text-text-primary"
    >
      {children}
    </Link>
  );
}
