'use client';

import Image from 'next/image';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  Mail,
  Lock,
  Eye,
  EyeOff,
  AlertCircle,
  MapPin,
  Receipt,
  FileCheck2,
  CloudUpload,
  CheckCircle2,
  ArrowUpRight,
  X,
} from 'lucide-react';
import { ForgotPasswordModal } from '@/components/forgot-password-modal';
import { SocialLoginButtons } from '@/components/social-login-buttons';

const HELP_TEXT =
  'Jika Anda mengalami kendala saat masuk (lupa email terdaftar, akun belum diaktivasi, atau kendala teknis lainnya), silakan hubungi Administrator instansi Anda atau kirim email ke support@tulap.id.';
const REGISTER_TEXT =
  'Pendaftaran akun mandiri hanya tersedia untuk Pegawai lapangan melalui aplikasi mobile Tulap.id. Akun Verifikator dan Admin di Dashboard ini dibuat oleh Administrator instansi Anda — hubungi Admin jika Anda belum memiliki akun.';
const TERMS_TEXT =
  'Tulap.id digunakan oleh pegawai instansi untuk pelaporan tugas lapangan secara akurat dan terverifikasi. Data lokasi, waktu, dan bukti foto dilindungi dengan enkripsi dan integritas anti-manipulasi.';
const PRIVACY_TEXT =
  'Data pribadi dan dokumentasi kegiatan lapangan diproses sesuai UU PDP No. 27/2022 dan hanya diakses oleh verifikator instansi yang berwenang.';

function InfoModal({
  title,
  body,
  onClose,
}: {
  title: string;
  body: string;
  onClose: () => void;
}) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
      <div className="w-full max-w-sm rounded-card bg-surface p-6 shadow-dropdown">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-body font-bold text-text-primary">{title}</h3>
          <button
            onClick={onClose}
            className="rounded-button p-1 text-text-secondary transition hover:bg-background hover:text-text-primary"
            aria-label="Tutup"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
        <p className="text-small leading-relaxed text-text-secondary">{body}</p>
        <button
          onClick={onClose}
          className="mt-5 w-full rounded-button bg-primary py-2.5 text-small font-semibold text-white shadow-sm transition hover:bg-primary-hover"
        >
          Mengerti
        </button>
      </div>
    </div>
  );
}

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showForgotPassword, setShowForgotPassword] = useState(false);
  const [infoModal, setInfoModal] = useState<{ title: string; body: string } | null>(null);

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
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-[#eef2fb] px-4 py-10">
      <div className="grid w-full max-w-5xl grid-cols-1 overflow-hidden rounded-card shadow-dropdown md:grid-cols-2">
        {/* LEFT — brand / illustration panel, hidden on mobile */}
        <div className="relative hidden min-h-[640px] flex-col justify-between overflow-hidden bg-[#003d75] p-10 text-white md:flex">
          {/* Ilustrasi petugas lapangan - aset sama dengan aplikasi mobile,
              menjaga konsistensi visual lintas platform. */}
          <Image
            src="/hero_illustration.png"
            alt=""
            fill
            priority
            className="pointer-events-none object-cover object-[center_35%]"
          />
          {/* Overlay gradien agar teks tetap terbaca di atas foto - dua pita
              terpisah (atas untuk judul, bawah untuk badge) supaya wajah
              karakter di tengah tetap terlihat jelas */}
          <div className="pointer-events-none absolute inset-x-0 top-0 h-64 bg-gradient-to-b from-[#003d75] via-[#003d75]/70 to-transparent" />
          <div className="pointer-events-none absolute inset-x-0 bottom-0 h-64 bg-gradient-to-t from-[#001c38] via-[#001c38]/60 to-transparent" />
          <MapPin className="pointer-events-none absolute right-10 top-24 z-10 h-5 w-5 text-white/25" />
          <MapPin className="pointer-events-none absolute right-24 top-10 z-10 h-4 w-4 text-white/20" />

          {/* Header */}
          <div className="relative z-10">
            <div className="flex items-center justify-between">
              <span className="text-section-title font-bold tracking-tight">Tulap.id</span>
              <span className="flex items-center gap-1.5 rounded-full bg-white/10 px-3 py-1 text-[11px] font-semibold text-white/90 ring-1 ring-white/20">
                <span className="h-1.5 w-1.5 rounded-full bg-success" />
                Online
              </span>
            </div>

            <h1 className="mt-8 text-[34px] font-bold leading-[1.15] tracking-tight">
              Tugas Lapangan
              <br />
              <span className="text-[#7fd4ff]">dalam Kendali</span>
            </h1>
            <p className="mt-4 max-w-xs text-small leading-relaxed text-white/80">
              Dokumentasikan kegiatan, validasi bukti, dan selesaikan laporan dalam satu tempat.
            </p>
          </div>

          {/* Badge & kartu verifikasi, melayang di atas ilustrasi */}
          <div className="relative z-10">
            <div className="inline-flex items-center gap-2 rounded-full bg-white/95 px-3 py-1.5 text-[11px] font-semibold text-text-primary shadow-lg">
              <CheckCircle2 className="h-3.5 w-3.5 text-success" />
              Lokasi Terverifikasi
              <span className="font-normal text-text-secondary">-6.2000, 106.8167</span>
            </div>

            {/* Floating verification cards */}
            <div className="mt-3 flex flex-wrap gap-3">
              <div className="flex items-center gap-2 rounded-xl bg-white/95 px-3 py-2 text-[11px] font-semibold text-text-primary shadow-lg">
                <Receipt className="h-4 w-4 text-primary" />
                Struk / OCR
                <CheckCircle2 className="h-3.5 w-3.5 text-success" />
              </div>
              <div className="flex items-center gap-2 rounded-xl bg-white/95 px-3 py-2 text-[11px] font-semibold text-text-primary shadow-lg">
                <FileCheck2 className="h-4 w-4 text-primary" />
                Laporan
                <CheckCircle2 className="h-3.5 w-3.5 text-success" />
              </div>
              <div className="flex items-center gap-2 rounded-xl bg-white/15 px-3 py-2 text-[11px] font-semibold text-white ring-1 ring-white/25">
                <CloudUpload className="h-4 w-4" />
                Sinkronisasi
              </div>
            </div>
          </div>
        </div>

        {/* RIGHT — login form */}
        <div className="flex flex-col justify-center bg-surface p-8 sm:p-10">
          <div className="flex flex-col items-center text-center">
            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-primary/10">
              <Image
                src="/logo.png"
                alt="Tulap.id"
                width={30}
                height={30}
                className="object-contain"
                priority
              />
            </div>
            <h2 className="mt-4 text-page-title font-bold text-text-primary">Masuk</h2>
            <p className="mt-1 text-small text-text-secondary">
              Masuk untuk melanjutkan tugas lapangan Anda.
            </p>
            <p className="mt-1 text-[11px] text-text-secondary">
              Belum memiliki akun?{' '}
              <button
                type="button"
                onClick={() => setInfoModal({ title: 'Daftar Akun', body: REGISTER_TEXT })}
                className="font-semibold text-primary hover:underline"
              >
                Daftar
              </button>
            </p>
          </div>

          <form onSubmit={handleSubmit} className="mt-6 space-y-4">
            <div className="space-y-1.5">
              <label htmlFor="email" className="text-xs font-semibold text-text-primary">
                Email
              </label>
              <div className="relative">
                <Mail className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-secondary" />
                <input
                  id="email"
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full rounded-button border border-border bg-surface py-2.5 pl-10 pr-4 text-small text-text-primary shadow-sm outline-none transition focus:border-primary focus:ring-1 focus:ring-primary"
                  placeholder="Masukkan email"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label htmlFor="password" className="text-xs font-semibold text-text-primary">
                Kata Sandi
              </label>
              <div className="relative">
                <Lock className="absolute left-3.5 top-1/2 h-4 w-4 -translate-y-1/2 text-text-secondary" />
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full rounded-button border border-border bg-surface py-2.5 pl-10 pr-10 text-small text-text-primary shadow-sm outline-none transition focus:border-primary focus:ring-1 focus:ring-primary"
                  placeholder="Masukkan kata sandi"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((s) => !s)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 text-text-secondary transition hover:text-text-primary"
                  aria-label={showPassword ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'}
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                </button>
              </div>
              <div className="flex justify-end">
                <button
                  type="button"
                  onClick={() => setShowForgotPassword(true)}
                  className="text-[11px] font-semibold text-primary hover:underline"
                >
                  Lupa kata sandi?
                </button>
              </div>
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
              className="flex w-full items-center justify-center gap-2 rounded-button bg-primary py-3 text-small font-semibold text-white shadow-sm transition hover:bg-primary-hover disabled:opacity-60"
            >
              {isSubmitting ? 'Memproses...' : 'Masuk'}
            </button>
          </form>

          <SocialLoginButtons onError={setError} />

          <div className="mt-6 text-center">
            <button
              type="button"
              onClick={() => setInfoModal({ title: 'Bantuan Masuk', body: HELP_TEXT })}
              className="inline-flex items-center gap-1 text-[11px] font-semibold text-primary hover:underline"
            >
              Butuh bantuan masuk?
              <ArrowUpRight className="h-3 w-3" />
            </button>
          </div>

          <div className="mt-6 border-t border-border/80 pt-5 text-center">
            <p className="text-[11px] leading-relaxed text-text-secondary">
              Dengan masuk, Anda menyetujui{' '}
              <button
                type="button"
                onClick={() => setInfoModal({ title: 'Syarat Penggunaan', body: TERMS_TEXT })}
                className="font-semibold text-primary hover:underline"
              >
                Syarat Penggunaan
              </button>{' '}
              dan{' '}
              <button
                type="button"
                onClick={() => setInfoModal({ title: 'Kebijakan Privasi', body: PRIVACY_TEXT })}
                className="font-semibold text-primary hover:underline"
              >
                Kebijakan Privasi
              </button>{' '}
              Tulap.id.
            </p>
          </div>
        </div>
      </div>

      {showForgotPassword && (
        <ForgotPasswordModal onClose={() => setShowForgotPassword(false)} />
      )}
      {infoModal && (
        <InfoModal
          title={infoModal.title}
          body={infoModal.body}
          onClose={() => setInfoModal(null)}
        />
      )}
    </div>
  );
}
