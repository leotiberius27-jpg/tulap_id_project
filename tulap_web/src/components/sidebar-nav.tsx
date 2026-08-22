'use client';

import Image from 'next/image';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  ClipboardList,
  PlusCircle,
  Users,
  FileCheck2,
  Settings,
} from 'lucide-react';
import { LogoutButton } from './logout-button';

interface SidebarNavProps {
  user: {
    fullName: string;
    role: string;
    instansiName: string;
    email: string;
  };
}

const ROLE_LABEL: Record<string, string> = {
  VERIFIKATOR: 'Verifikator',
  ADMIN: 'Admin Instansi',
  SUPER_ADMIN: 'Super Admin',
  PEGAWAI: 'Pegawai Lapangan',
};

export function SidebarNav({ user }: SidebarNavProps) {
  const pathname = usePathname();
  const isAdmin = user.role === 'ADMIN' || user.role === 'SUPER_ADMIN';

  const navItems = [
    {
      label: 'Dashboard',
      href: '/tasks',
      icon: LayoutDashboard,
      active: pathname === '/tasks' && !pathname.includes('/new'),
    },
    {
      label: 'Antrean Tugas',
      href: '/tasks?status=PENDING_VERIFICATION',
      icon: ClipboardList,
      active: pathname.startsWith('/tasks') && !pathname.includes('/new') && !pathname.includes('/employees'),
    },
    ...(isAdmin
      ? [
          {
            label: 'Buat Tugas',
            href: '/tasks/new',
            icon: PlusCircle,
            active: pathname === '/tasks/new',
          },
          {
            label: 'Pegawai',
            href: '/employees',
            icon: Users,
            active: pathname.startsWith('/employees'),
          },
        ]
      : []),
    {
      label: 'Verifikasi LPJ',
      href: '/tasks?status=VERIFIED',
      icon: FileCheck2,
      active: false,
    },
    {
      label: 'Pengaturan',
      href: '#',
      icon: Settings,
      active: false,
    },
  ];

  const initials = user.fullName
    .split(' ')
    .slice(0, 2)
    .map((n) => n[0])
    .join('')
    .toUpperCase();

  return (
    <aside className="w-64 bg-surface border-r border-border flex flex-col justify-between p-5 min-h-screen sticky top-0 shrink-0">
      <div>
        {/* Brand Logo & Title */}
        <div className="flex items-center gap-3 px-2 py-3 mb-6">
          <div className="w-10 h-10 rounded-xl bg-primary/5 flex items-center justify-center p-1 shrink-0">
            <Image
              src="/logo.png"
              alt="Tulap.id Logo"
              width={34}
              height={34}
              className="object-contain"
              priority
            />
          </div>
          <div>
            <h1 className="text-section-title font-bold text-primary tracking-tight">Tulap.id</h1>
            <p className="text-[11px] text-text-secondary font-medium">Dashboard Verifikasi</p>
          </div>
        </div>

        {/* Navigation Menu */}
        <nav className="space-y-1.5">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.label}
                href={item.href}
                className={`flex items-center gap-3.5 px-3.5 py-2.5 rounded-button text-small font-medium transition-all ${
                  item.active
                    ? 'bg-primary text-white shadow-sm'
                    : 'text-text-secondary hover:bg-background hover:text-text-primary'
                }`}
              >
                <Icon className={`w-5 h-5 ${item.active ? 'text-white' : 'text-text-secondary'}`} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </nav>
      </div>

      {/* User Profile & Logout Bottom Section */}
      <div className="border-t border-border pt-4 mt-auto">
        <div className="flex items-center gap-3 px-2 py-2 mb-2 rounded-card bg-background/60">
          <div className="w-9 h-9 rounded-full bg-primary/10 text-primary font-bold text-xs flex items-center justify-center shrink-0 border border-primary/20">
            {initials || 'TL'}
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-small font-semibold text-text-primary truncate">{user.fullName}</p>
            <p className="text-[11px] text-text-secondary truncate">
              {ROLE_LABEL[user.role] ?? user.role}
            </p>
          </div>
        </div>

        <div className="px-1">
          <LogoutButton />
        </div>
      </div>
    </aside>
  );
}
