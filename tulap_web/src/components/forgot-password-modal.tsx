'use client';

import { useState } from 'react';
import { X, Mail, KeyRound, ArrowRight, CheckCircle2, AlertCircle } from 'lucide-react';

type Step = 'email' | 'reset' | 'done';

export function ForgotPasswordModal({ onClose }: { onClose: () => void }) {
  const [step, setStep] = useState<Step>('email');
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleRequestCode(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/auth/forgot-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.message ?? 'Gagal mengirim kode.');
        return;
      }
      setStep('reset');
    } catch {
      setError('Tidak dapat terhubung ke server.');
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleResetPassword(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);
    try {
      const res = await fetch('/api/auth/reset-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, code, newPassword }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.message ?? 'Kode reset tidak valid atau telah kedaluwarsa.');
        return;
      }
      setStep('done');
    } catch {
      setError('Tidak dapat terhubung ke server.');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
      <div className="w-full max-w-sm rounded-card bg-surface p-6 shadow-dropdown">
        <div className="mb-5 flex items-center justify-between">
          <h3 className="text-body font-bold text-text-primary">
            {step === 'email' && 'Lupa Kata Sandi'}
            {step === 'reset' && 'Masukkan Kode Reset'}
            {step === 'done' && 'Kata Sandi Diperbarui'}
          </h3>
          <button
            onClick={onClose}
            className="rounded-button p-1 text-text-secondary transition hover:bg-background hover:text-text-primary"
            aria-label="Tutup"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {step === 'email' && (
          <form onSubmit={handleRequestCode} className="space-y-4">
            <p className="text-small text-text-secondary">
              Masukkan email akun Anda. Kami akan mengirim kode reset 6-digit jika email
              terdaftar.
            </p>
            <div className="relative">
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="nama@instansi.go.id"
                className="w-full rounded-button border border-border bg-surface py-2.5 pl-10 pr-4 text-small text-text-primary shadow-sm outline-none transition focus:border-primary focus:ring-1 focus:ring-primary"
              />
              <Mail className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-secondary" />
            </div>
            {error && (
              <div className="flex items-center gap-2 rounded-button border border-danger/20 bg-danger-soft/80 p-3 text-xs text-danger">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}
            <button
              type="submit"
              disabled={isSubmitting}
              className="flex w-full items-center justify-center gap-2 rounded-button bg-primary py-2.5 text-small font-semibold text-white shadow-sm transition hover:bg-primary-hover disabled:opacity-60"
            >
              <span>{isSubmitting ? 'Mengirim...' : 'Kirim Kode Reset'}</span>
              {!isSubmitting && <ArrowRight className="h-4 w-4" />}
            </button>
          </form>
        )}

        {step === 'reset' && (
          <form onSubmit={handleResetPassword} className="space-y-4">
            <p className="text-small text-text-secondary">
              Kode 6-digit dikirim ke <span className="font-medium text-text-primary">{email}</span>.
              Berlaku dalam waktu terbatas.
            </p>
            <div className="relative">
              <input
                type="text"
                required
                inputMode="numeric"
                maxLength={6}
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, ''))}
                placeholder="123456"
                className="w-full rounded-button border border-border bg-surface py-2.5 pl-10 pr-4 text-small tracking-[0.3em] text-text-primary shadow-sm outline-none transition focus:border-primary focus:ring-1 focus:ring-primary"
              />
              <KeyRound className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-secondary" />
            </div>
            <div className="relative">
              <input
                type="password"
                required
                minLength={8}
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder="Kata sandi baru (min. 8 karakter)"
                className="w-full rounded-button border border-border bg-surface py-2.5 pl-4 pr-4 text-small text-text-primary shadow-sm outline-none transition focus:border-primary focus:ring-1 focus:ring-primary"
              />
            </div>
            {error && (
              <div className="flex items-center gap-2 rounded-button border border-danger/20 bg-danger-soft/80 p-3 text-xs text-danger">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}
            <button
              type="submit"
              disabled={isSubmitting}
              className="flex w-full items-center justify-center gap-2 rounded-button bg-primary py-2.5 text-small font-semibold text-white shadow-sm transition hover:bg-primary-hover disabled:opacity-60"
            >
              <span>{isSubmitting ? 'Memproses...' : 'Perbarui Kata Sandi'}</span>
              {!isSubmitting && <ArrowRight className="h-4 w-4" />}
            </button>
            <button
              type="button"
              onClick={() => setStep('email')}
              className="w-full text-center text-xs font-medium text-text-secondary hover:text-text-primary"
            >
              Kirim ulang kode / ganti email
            </button>
          </form>
        )}

        {step === 'done' && (
          <div className="flex flex-col items-center gap-3 py-2 text-center">
            <CheckCircle2 className="h-10 w-10 text-success" />
            <p className="text-small text-text-secondary">
              Kata sandi berhasil diperbarui. Silakan masuk dengan kata sandi baru Anda.
            </p>
            <button
              onClick={onClose}
              className="mt-2 w-full rounded-button bg-primary py-2.5 text-small font-semibold text-white shadow-sm transition hover:bg-primary-hover"
            >
              Kembali ke Login
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
