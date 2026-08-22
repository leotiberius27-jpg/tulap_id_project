'use client';

import Image from 'next/image';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Mail, Lock, AlertCircle, ArrowRight } from 'lucide-react';

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
    <div className="flex min-h-screen items-center justify-center bg-[#f8fafc] px-4 py-12">
      <div className="w-full max-w-md rounded-2xl bg-surface p-8 sm:p-10 border border-border/80 shadow-dropdown">
        {/* Brand Logo & Header */}
        <div className="flex flex-col items-center text-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-primary/5 flex items-center justify-center mb-4 p-2">
            <Image
              src="/logo.png"
              alt="Tulap.id Logo"
              width={54}
              height={54}
              className="object-contain"
              priority
            />
          </div>
          <h1 className="text-2xl font-bold text-primary tracking-tight">Tulap.id</h1>
          <p className="mt-1 text-small text-text-secondary">
            Dashboard Manajemen Tugas &amp; Verifikasi LPJ
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1.5">
            <label htmlFor="email" className="text-xs font-semibold text-text-primary uppercase tracking-wider">
              Email Pengguna
            </label>
            <div className="relative">
              <input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-button border border-border pl-10 pr-4 py-2.5 text-small bg-surface text-text-primary outline-none focus:border-primary focus:ring-1 focus:ring-primary shadow-sm transition"
                placeholder="nama@instansi.go.id"
              />
              <Mail className="w-4 h-4 text-text-secondary absolute left-3.5 top-1/2 -translate-y-1/2" />
            </div>
          </div>

          <div className="space-y-1.5">
            <div className="flex items-center justify-between">
              <label htmlFor="password" className="text-xs font-semibold text-text-primary uppercase tracking-wider">
                Kata Sandi
              </label>
            </div>
            <div className="relative">
              <input
                id="password"
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full rounded-button border border-border pl-10 pr-4 py-2.5 text-small bg-surface text-text-primary outline-none focus:border-primary focus:ring-1 focus:ring-primary shadow-sm transition"
                placeholder="••••••••"
              />
              <Lock className="w-4 h-4 text-text-secondary absolute left-3.5 top-1/2 -translate-y-1/2" />
            </div>
          </div>

          {error && (
            <div className="flex items-center gap-2 rounded-button bg-danger-soft/80 border border-danger/20 p-3 text-xs text-danger">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full mt-2 flex items-center justify-center gap-2 rounded-button bg-primary py-3 text-small font-semibold text-white transition hover:bg-primary-hover shadow-sm disabled:opacity-60"
          >
            <span>{isSubmitting ? 'Memproses Masuk...' : 'Masuk ke Dashboard'}</span>
            {!isSubmitting && <ArrowRight className="w-4 h-4" />}
          </button>
        </form>

        <div className="mt-8 pt-6 border-t border-border/80 text-center">
          <p className="text-[11px] text-text-secondary">
            Sistem Informasi Penugasan &amp; Verifikasi Akuntabilitas Lapangan Resmi.
          </p>
        </div>
      </div>
    </div>
  );
}
