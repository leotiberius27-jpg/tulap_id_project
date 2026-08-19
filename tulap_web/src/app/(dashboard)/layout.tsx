import { redirect } from 'next/navigation';
import { getSession } from '@/lib/session';
import { LogoutButton } from '@/components/logout-button';

const ROLE_LABEL: Record<string, string> = {
  VERIFIKATOR: 'Verifikator',
  ADMIN: 'Admin Instansi',
  SUPER_ADMIN: 'Super Admin',
};

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
          <div>
            <p className="text-section-title font-bold text-primary">Tulap.id</p>
            <p className="text-small text-text-secondary">Dashboard Verifikasi &amp; LPJ</p>
          </div>
          <div className="flex items-center gap-4">
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
