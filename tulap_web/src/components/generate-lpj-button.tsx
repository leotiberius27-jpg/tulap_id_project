'use client';

import { useState } from 'react';

export function GenerateLpjButton({ taskId, taskCode }: { taskId: string; taskCode: string }) {
  const [isGenerating, setIsGenerating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleGenerate() {
    setError(null);
    setIsGenerating(true);

    try {
      const response = await fetch('/api/lpj', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ taskId }),
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        setError(data.message ?? 'LPJ gagal dibuat.');
        return;
      }

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `LPJ-${taskCode}.pdf`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } catch {
      setError('Tidak dapat terhubung ke server.');
    } finally {
      setIsGenerating(false);
    }
  }

  return (
    <div className="rounded-card bg-surface p-5 shadow-card">
      <p className="mb-3 text-small font-semibold text-text-primary">Laporan Pertanggungjawaban</p>
      <button
        onClick={handleGenerate}
        disabled={isGenerating}
        className="rounded-button bg-primary px-4 py-2 text-small font-semibold text-white transition hover:bg-primary-hover disabled:opacity-60"
      >
        {isGenerating ? 'Membuat PDF...' : 'Unduh LPJ (PDF)'}
      </button>
      {error && <p className="mt-3 text-small text-danger">{error}</p>}
    </div>
  );
}
