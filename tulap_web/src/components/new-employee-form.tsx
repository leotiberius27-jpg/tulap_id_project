'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { RoleName } from '@/lib/types';

const INPUT_CLASS =
  'w-full rounded-button border border-border px-3 py-2.5 text-body outline-none focus:border-primary';

const ROLE_OPTIONS: { value: RoleName; label: string }[] = [
  { value: 'PEGAWAI', label: 'Petugas' },
  { value: 'VERIFIKATOR', label: 'Verifikator' },
  { value: 'ADMIN', label: 'Admin' },
  { value: 'SUPER_ADMIN', label: 'Super Admin' },
];

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

export function NewEmployeeForm({ canAssignSuperAdmin }: { canAssignSuperAdmin: boolean }) {
  const router = useRouter();
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [nip, setNip] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [instansiName, setInstansiName] = useState('');
  const [unitKerja, setUnitKerja] = useState('');
  const [roleName, setRoleName] = useState<RoleName>('PEGAWAI');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const roleOptions = canAssignSuperAdmin
    ? ROLE_OPTIONS
    : ROLE_OPTIONS.filter((r) => r.value !== 'SUPER_ADMIN');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      const response = await fetch('/api/employees', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fullName,
          email,
          password,
          nip: nip || undefined,
          phoneNumber: phoneNumber || undefined,
          instansiName: instansiName || undefined,
          unitKerja: unitKerja || undefined,
          roleName,
        }),
      });
      const data = await response.json();

      if (!response.ok) {
        setError(data.message ?? 'Gagal mendaftarkan pegawai.');
        return;
      }

      router.push('/employees');
      router.refresh();
    } catch {
      setError('Tidak dapat terhubung ke server.');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-4 rounded-card bg-surface p-6 shadow-card">
      <Field label="Nama Lengkap" htmlFor="fullName">
        <input
          id="fullName"
          required
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
          className={INPUT_CLASS}
        />
      </Field>

      <Field label="Email" htmlFor="email">
        <input
          id="email"
          type="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className={INPUT_CLASS}
          placeholder="nama@instansi.go.id"
        />
      </Field>

      <Field label="Password Awal" htmlFor="password">
        <input
          id="password"
          type="password"
          required
          minLength={8}
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className={INPUT_CLASS}
          placeholder="Minimal 8 karakter"
        />
      </Field>

      <Field label="Peran" htmlFor="roleName">
        <select
          id="roleName"
          value={roleName}
          onChange={(e) => setRoleName(e.target.value as RoleName)}
          className={INPUT_CLASS}
        >
          {roleOptions.map((r) => (
            <option key={r.value} value={r.value}>
              {r.label}
            </option>
          ))}
        </select>
      </Field>

      <Field label="NIP (opsional)" htmlFor="nip">
        <input id="nip" value={nip} onChange={(e) => setNip(e.target.value)} className={INPUT_CLASS} />
      </Field>

      <Field label="Nomor Telepon (opsional)" htmlFor="phoneNumber">
        <input
          id="phoneNumber"
          value={phoneNumber}
          onChange={(e) => setPhoneNumber(e.target.value)}
          className={INPUT_CLASS}
        />
      </Field>

      <Field label="Instansi (opsional)" htmlFor="instansiName">
        <input
          id="instansiName"
          value={instansiName}
          onChange={(e) => setInstansiName(e.target.value)}
          className={INPUT_CLASS}
        />
      </Field>

      <Field label="Unit Kerja (opsional)" htmlFor="unitKerja">
        <input
          id="unitKerja"
          value={unitKerja}
          onChange={(e) => setUnitKerja(e.target.value)}
          className={INPUT_CLASS}
        />
      </Field>

      {error && (
        <p className="rounded-small bg-danger-soft px-3 py-2 text-small text-danger">{error}</p>
      )}

      <button
        type="submit"
        disabled={isSubmitting}
        className="mt-2 rounded-button bg-primary px-5 py-2.5 text-body font-semibold text-white transition hover:bg-primary-hover disabled:opacity-60"
      >
        {isSubmitting ? 'Menyimpan...' : 'Daftarkan Pegawai'}
      </button>
    </form>
  );
}
