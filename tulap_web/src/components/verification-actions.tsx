'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';

// "approve" tidak butuh catatan - hanya "request-revision"/"reject" yang
// WAJIB disertai alasan spesifik (backend menolak tanpa `note`, min 3
// karakter), sesuai Bagian 22: Verifikator menunjuk item spesifik
// ("Nota BBM - Nominal kurang jelas"), bukan sekadar mengubah status.
const NOTE_ACTIONS = [
  {
    key: 'request-revision',
    label: 'Minta Revisi',
    className: 'bg-warning text-white hover:opacity-90',
    placeholder: 'Contoh: Nota BBM - Nominal kurang jelas.',
  },
  {
    key: 'reject',
    label: 'Tolak',
    className: 'bg-danger text-white hover:opacity-90',
    placeholder: 'Jelaskan alasan penolakan...',
  },
] as const;

type NoteAction = (typeof NOTE_ACTIONS)[number]['key'];

export function VerificationActions({ taskId }: { taskId: string }) {
  const router = useRouter();
  const [pendingAction, setPendingAction] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [openNoteFor, setOpenNoteFor] = useState<NoteAction | null>(null);
  const [note, setNote] = useState('');

  async function submit(action: string, body?: Record<string, unknown>) {
    setError(null);
    setPendingAction(action);

    try {
      const response = await fetch(`/api/tasks/${taskId}/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body ?? {}),
      });
      const data = await response.json();

      if (!response.ok) {
        setError(data.message ?? 'Aksi gagal dijalankan.');
        return;
      }

      setOpenNoteFor(null);
      setNote('');
      router.refresh();
    } catch {
      setError('Tidak dapat terhubung ke server.');
    } finally {
      setPendingAction(null);
    }
  }

  function handleNoteSubmit(action: NoteAction) {
    if (note.trim().length < 3) {
      setError('Catatan terlalu pendek, jelaskan apa yang perlu diperbaiki.');
      return;
    }
    submit(action, { note: note.trim() });
  }

  return (
    <div className="rounded-card bg-surface p-5 shadow-card">
      <p className="mb-3 text-small font-semibold text-text-primary">Keputusan Verifikasi</p>
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => submit('approve')}
          disabled={pendingAction !== null}
          className="rounded-button bg-success px-4 py-2 text-small font-semibold text-white transition hover:opacity-90 disabled:opacity-60"
        >
          {pendingAction === 'approve' ? 'Memproses...' : 'Setujui'}
        </button>
        {NOTE_ACTIONS.map((action) => (
          <button
            key={action.key}
            onClick={() => {
              setError(null);
              setNote('');
              setOpenNoteFor(openNoteFor === action.key ? null : action.key);
            }}
            disabled={pendingAction !== null}
            className={`rounded-button px-4 py-2 text-small font-semibold transition disabled:opacity-60 ${action.className}`}
          >
            {pendingAction === action.key ? 'Memproses...' : action.label}
          </button>
        ))}
      </div>

      {openNoteFor && (
        <div className="mt-4 flex flex-col gap-2 border-t border-border pt-4">
          <label className="text-small font-medium text-text-primary">
            Catatan untuk Petugas (wajib)
          </label>
          <textarea
            autoFocus
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder={NOTE_ACTIONS.find((a) => a.key === openNoteFor)?.placeholder}
            className="min-h-20 w-full rounded-button border border-border px-3 py-2.5 text-body outline-none focus:border-primary"
          />
          <div className="flex gap-2">
            <button
              onClick={() => handleNoteSubmit(openNoteFor)}
              disabled={pendingAction !== null}
              className="rounded-button bg-primary px-4 py-2 text-small font-semibold text-white transition hover:bg-primary-hover disabled:opacity-60"
            >
              Kirim
            </button>
            <button
              onClick={() => setOpenNoteFor(null)}
              className="rounded-button px-4 py-2 text-small font-medium text-text-secondary hover:bg-background"
            >
              Batal
            </button>
          </div>
        </div>
      )}

      {error && <p className="mt-3 text-small text-danger">{error}</p>}
    </div>
  );
}
