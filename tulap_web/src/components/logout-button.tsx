'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';

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
      className="rounded-button border border-border px-3 py-1.5 text-small font-medium text-text-secondary transition hover:border-danger hover:text-danger disabled:opacity-60"
    >
      {isLoading ? 'Keluar...' : 'Keluar'}
    </button>
  );
}
