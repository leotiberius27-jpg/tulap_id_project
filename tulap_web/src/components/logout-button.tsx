'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { LogOut } from 'lucide-react';

export function LogoutButton() {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);

  async function handleLogout() {
    setIsLoading(true);
    await fetch('/api/auth/logout', { method: 'POST' });
    router.push('/login');
    router.refresh();
  }

  return (
    <button
      onClick={handleLogout}
      disabled={isLoading}
      className="w-full flex items-center gap-2.5 px-3 py-2 rounded-button text-small font-medium text-text-secondary hover:text-danger hover:bg-danger-soft/60 transition disabled:opacity-60"
    >
      <LogOut className="w-4 h-4 shrink-0" />
      <span>{isLoading ? 'Keluar...' : 'Keluar'}</span>
    </button>
  );
}
