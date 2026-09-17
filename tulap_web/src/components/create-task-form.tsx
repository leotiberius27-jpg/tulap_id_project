'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Employee } from '@/lib/types';

type ChecklistDraft = { label: string; isMandatory: boolean };

const emptyItem: ChecklistDraft = { label: '', isMandatory: true };

const INPUT_CLASS =
  'w-full rounded-button border border-border px-3 py-2.5 text-body outline-none focus:border-primary';

function Field({
  label,
  htmlFor,
  children,
}: {
  label: string;
  htmlFor: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex flex-col gap-1.5">
      <label htmlFor={htmlFor} className="text-small font-medium text-text-primary">
        {label}
      </label>
      {children}
    </div>
  );
}

export function CreateTaskForm({ employees }: { employees: Employee[] }) {
  const router = useRouter();
  const [taskName, setTaskName] = useState('');
  const [destination, setDestination] = useState('');
  const [description, setDescription] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [budgetAmount, setBudgetAmount] = useState('');
  const [assigneeId, setAssigneeId] = useState('');
  const [items, setItems] = useState<ChecklistDraft[]>([{ ...emptyItem }]);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  function updateItem(index: number, patch: Partial<ChecklistDraft>) {
    setItems((prev) => prev.map((item, i) => (i === index ? { ...item, ...patch } : item)));
  }

  function addItem() {
    setItems((prev) => [...prev, { ...emptyItem }]);
  }

  function removeItem(index: number) {
    setItems((prev) => prev.filter((_, i) => i !== index));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    const validItems = items
      .map((item, index) => ({ ...item, order: index }))
      .filter((item) => item.label.trim().length > 0);

    if (validItems.length === 0) {
      setError('Minimal satu item checklist diperlukan.');
      return;
    }

    setIsSubmitting(true);
    try {
      const taskResponse = await fetch('/api/tasks', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          taskName,
          destination,
          description: description || undefined,
          startDate,
          endDate,
          budgetAmount: Number(budgetAmount),
          assigneeId,
        }),
      });
      const task = await taskResponse.json();

      if (!taskResponse.ok) {
        setError(task.message ?? 'Gagal membuat tugas.');
        return;
      }

      const checklistResponse = await fetch(`/api/tasks/${task.id}/checklist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ items: validItems }),
      });

      if (!checklistResponse.ok) {
        const data = await checklistResponse.json();
        setError(
          `Tugas dibuat, tetapi checklist gagal disimpan: ${data.message ?? 'kesalahan tidak diketahui'}.`,
        );
        return;
      }

      router.push(`/tasks/${task.id}`);
      router.refresh();
    } catch {
      setError('Tidak dapat terhubung ke server.');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-6">
      <div className="rounded-card bg-surface p-6 shadow-card">
        <p className="mb-4 text-small font-semibold text-text-primary">Detail Tugas</p>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Field label="Nama Tugas" htmlFor="taskName">
            <input
              id="taskName"
              required
              value={taskName}
              onChange={(e) => setTaskName(e.target.value)}
              className={INPUT_CLASS}
              placeholder="Inspeksi Jembatan Ciliwung"
            />
          </Field>

          <Field label="Lokasi/Destinasi" htmlFor="destination">
            <input
              id="destination"
              required
              value={destination}
              onChange={(e) => setDestination(e.target.value)}
              className={INPUT_CLASS}
              placeholder="Jakarta Timur"
            />
          </Field>

          <Field label="Petugas" htmlFor="assigneeId">
            <select
              id="assigneeId"
              required
              value={assigneeId}
              onChange={(e) => setAssigneeId(e.target.value)}
              className={INPUT_CLASS}
            >
              <option value="" disabled>
                Pilih petugas...
              </option>
              {employees.map((employee) => (
                <option key={employee.id} value={employee.id}>
                  {employee.fullName} · {employee.instansiName ?? 'Tanpa instansi'}
                </option>
              ))}
            </select>
            {employees.length === 0 && (
              <p className="mt-1 text-small text-danger">
                Belum ada pegawai berperan Petugas. Tambahkan lewat menu Pegawai terlebih dahulu.
              </p>
            )}
          </Field>

          <Field label="Anggaran (Rp)" htmlFor="budgetAmount">
            <input
              id="budgetAmount"
              type="number"
              min={0}
              required
              value={budgetAmount}
              onChange={(e) => setBudgetAmount(e.target.value)}
              className={INPUT_CLASS}
              placeholder="1500000"
            />
          </Field>

          <Field label="Tanggal Mulai" htmlFor="startDate">
            <input
              id="startDate"
              type="date"
              required
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className={INPUT_CLASS}
            />
          </Field>

          <Field label="Tanggal Selesai (Deadline)" htmlFor="endDate">
            <input
              id="endDate"
              type="date"
              required
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className={INPUT_CLASS}
            />
          </Field>
        </div>

        <div className="mt-4">
          <Field label="Deskripsi / Instruksi (opsional)" htmlFor="description">
            <textarea
              id="description"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className={`${INPUT_CLASS} min-h-24`}
              placeholder="Instruksi singkat untuk petugas..."
            />
          </Field>
        </div>
      </div>

      <div className="rounded-card bg-surface p-6 shadow-card">
        <div className="mb-4 flex items-center justify-between">
          <p className="text-small font-semibold text-text-primary">
            Checklist &amp; Bukti Wajib
          </p>
          <button
            type="button"
            onClick={addItem}
            className="rounded-button bg-background px-3 py-1.5 text-small font-medium text-primary hover:bg-border"
          >
            + Tambah Item
          </button>
        </div>

        <div className="flex flex-col gap-3">
          {items.map((item, index) => (
            <div key={index} className="flex items-center gap-3">
              <input
                value={item.label}
                onChange={(e) => updateItem(index, { label: e.target.value })}
                className={`${INPUT_CLASS} flex-1`}
                placeholder={`Contoh: ${index === 0 ? 'Foto kondisi awal' : 'Foto kegiatan'}`}
              />
              <label className="flex items-center gap-1.5 whitespace-nowrap text-small text-text-secondary">
                <input
                  type="checkbox"
                  checked={item.isMandatory}
                  onChange={(e) => updateItem(index, { isMandatory: e.target.checked })}
                />
                Wajib
              </label>
              {items.length > 1 && (
                <button
                  type="button"
                  onClick={() => removeItem(index)}
                  className="text-small text-danger hover:underline"
                >
                  Hapus
                </button>
              )}
            </div>
          ))}
        </div>
      </div>

      {error && (
        <p className="rounded-small bg-danger-soft px-3 py-2 text-small text-danger">{error}</p>
      )}

      <div className="flex justify-end gap-3">
        <button
          type="submit"
          disabled={isSubmitting}
          className="rounded-button bg-primary px-5 py-2.5 text-body font-semibold text-white transition hover:bg-primary-hover disabled:opacity-60"
        >
          {isSubmitting ? 'Menyimpan...' : 'Buat Tugas'}
        </button>
      </div>
    </form>
  );
}
