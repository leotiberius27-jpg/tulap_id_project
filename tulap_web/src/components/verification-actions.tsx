'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';

const ACTIONS = [
  { key: 'approve', label: 'Setujui', className: 'bg-success text-white hover:opacity-90' },
  {
    key: 'request-revision',
    label: 'Minta Revisi',
    className: 'bg-warning text-white hover:opacity-90',
  },
  { key: 'reject', label: 'Tolak', className: 'bg-danger text-white hover:opacity-90' },
] as const;

export function VerificationActions({ taskId }: { taskId: string }) {
  const router = useRouter();
  const [pendingAction, setPendingAction] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function handleAction(action: (typeof ACTIONS)[number]['key']) {
    setError(null);
    setPendingAction(action);

    try {
      const response = await fetch(`/api/tasks/${taskId}/${action}`, { method: 'POST' });
      const data = await response.json();

      if (!response.ok) {
        setError(data.message ?? 'Aksi gagal dijalankan.');
        return;
      }

      router.refresh();
    } catch {
      setError('Tidak dapat terhubung ke server.');
    } finally {
      setPendingAction(null);
    }
  }

  return (
    <div className="rounded-card bg-surface p-5 shadow-card">
      <p className="mb-3 text-small font-semibold text-text-primary">Keputusan Verifikasi</p>
      <div className="flex flex-wrap gap-2">
        {ACTIONS.map((action) => (
          <button
            key={action.key}
            onClick={() => handleAction(action.key)}
            disabled={pendingAction !== null}
            className={`rounded-button px-4 py-2 text-small font-semibold transition disabled:opacity-60 ${action.className}`}
          >
            {pendingAction === action.key ? 'Memproses...' : action.label}
          </button>
        ))}
      </div>
      {error && <p className="mt-3 text-small text-danger">{error}</p>}
    </div>
  );
}
