'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';

export function EmployeeActions({ id, isActive }: { id: string; isActive: boolean }) {
  const router = useRouter();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleToggle() {
    setError(null);
    setIsSubmitting(true);
    try {
      const response = await fetch(
        isActive ? `/api/employees/${id}` : `/api/employees/${id}/reactivate`,
        { method: isActive ? 'DELETE' : 'POST' },
      );
      const data = await response.json();

      if (!response.ok) {
        setError(data.message ?? 'Aksi gagal dijalankan.');
        return;
      }

      router.refresh();
    } catch {
      setError('Tidak dapat terhubung ke server.');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <button
        onClick={handleToggle}
        disabled={isSubmitting}
        className={`rounded-button px-3 py-1.5 text-small font-medium transition disabled:opacity-60 ${
          isActive
            ? 'bg-danger-soft text-danger hover:opacity-90'
            : 'bg-success text-white hover:opacity-90'
        }`}
      >
        {isSubmitting ? 'Memproses...' : isActive ? 'Nonaktifkan' : 'Aktifkan'}
      </button>
      {error && <p className="text-small text-danger">{error}</p>}
    </div>
  );
}
