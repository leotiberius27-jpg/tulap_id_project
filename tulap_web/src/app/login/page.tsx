'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data = await response.json();

      if (!response.ok) {
        setError(data.message ?? 'Login gagal.');
        return;
      }

      router.push('/tasks');
      router.refresh();
    } catch {
      setError('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-background px-4">
      <div className="w-full max-w-sm rounded-card bg-surface p-8 shadow-card">
        <h1 className="text-page-title text-text-primary">Tulap.id</h1>
        <p className="mb-6 mt-1 text-small text-text-secondary">
          Dashboard Verifikasi &amp; LPJ
        </p>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <label htmlFor="email" className="text-small font-medium text-text-primary">
              Email
            </label>
            <input
              id="email"
              type="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="rounded-button border border-border px-3 py-2.5 text-body outline-none focus:border-primary"
              placeholder="nama@instansi.go.id"
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label htmlFor="password" className="text-small font-medium text-text-primary">
              Password
            </label>
            <input
              id="password"
              type="password"
              required
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="rounded-button border border-border px-3 py-2.5 text-body outline-none focus:border-primary"
              placeholder="••••••••"
            />
          </div>

          {error && (
            <p className="rounded-small bg-danger-soft px-3 py-2 text-small text-danger">
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={isSubmitting}
            className="mt-2 rounded-button bg-primary px-4 py-2.5 text-body font-semibold text-white transition hover:bg-primary-hover disabled:opacity-60"
          >
            {isSubmitting ? 'Memproses...' : 'Masuk'}
          </button>
        </form>
      </div>
    </div>
  );
}
