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
  FileCheck2,
  CloudUpload,
  Check,
  X,
} from 'lucide-react';
import { ForgotPasswordModal } from '@/components/forgot-password-modal';
import { SocialLoginButtons } from '@/components/social-login-buttons';

const HELP_TEXT =
  'Jika Anda mengalami kendala saat masuk (lupa email terdaftar, akun belum diaktivasi, atau kendala teknis lainnya), silakan hubungi Administrator instansi Anda atau kirim email ke support@tulap.id.';
const REGISTER_TEXT =
  'Pendaftaran akun mandiri untuk Pegawai lapangan dapat dilakukan melalui aplikasi mobile Tulap.id atau melalui undangan Administrator instansi Anda.';
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
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4 backdrop-blur-sm">
      <div className="w-full max-w-sm rounded-[24px] bg-white p-6 shadow-2xl ring-1 ring-slate-100 animate-in fade-in zoom-in-95 duration-200">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-lg font-bold text-slate-800">{title}</h3>
          <button
            onClick={onClose}
            className="rounded-full p-1.5 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700"
            aria-label="Tutup"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
        <p className="text-sm leading-relaxed text-slate-600">{body}</p>
        <button
          onClick={onClose}
          className="mt-6 w-full rounded-xl bg-[#0d52d7] py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-[#0b45b5]"
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
  const [isOnline, setIsOnline] = useState(true);

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
    <main className="min-h-screen w-full flex flex-col lg:flex-row bg-[#f3f7fb] overflow-x-hidden font-sans">
      {/* =========================================================================
          LEFT COLUMN: HERO BRANDING & PRODUCT SHOWCASE (Matching Web Reference)
          ========================================================================= */}
      <section className="relative w-full lg:w-[56%] xl:w-[58%] bg-gradient-to-b from-[#0050cf] via-[#005ee6] to-[#006bf8] text-white flex flex-col justify-between p-6 sm:p-10 lg:p-14 overflow-hidden min-h-[580px] lg:min-h-screen">
        {/* Subtle Topographic & Grid Pattern Background with Sway Animation */}
        <div className="absolute inset-0 pointer-events-none opacity-30 animate-contour">
          <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none" viewBox="0 0 800 1000">
            <path
              d="M-50,150 C200,80 400,220 850,120 M-50,280 C220,200 450,340 850,240 M-50,420 C180,350 420,480 850,380 M-50,600 C240,520 500,680 850,560 M-50,750 C190,680 440,820 850,710 M-50,900 C230,830 480,950 850,860"
              fill="none"
              stroke="white"
              strokeWidth="1.2"
              strokeDasharray="4 8"
              opacity="0.35"
            />
            <path
              d="M-50,200 C300,120 500,300 850,180 M-50,350 C260,250 490,410 850,300 M-50,520 C200,430 470,590 850,480 M-50,700 C280,600 520,770 850,650 M-50,850 C220,760 480,900 850,800"
              fill="none"
              stroke="white"
              strokeWidth="1.5"
              opacity="0.25"
            />
          </svg>
        </div>

        {/* Ambient Top Glow and Dot Grid */}
        <div className="absolute inset-0 pointer-events-none bg-[radial-gradient(circle_at_25%_15%,rgba(125,211,252,0.2),transparent_35%)]" />
        <div className="absolute top-0 right-0 w-96 h-96 pointer-events-none bg-[radial-gradient(circle,rgba(255,255,255,0.08)_1.5px,transparent_1.5px)] [background-size:24px_24px] opacity-40" />

        {/* TOP BAR: Logo & Status Badge */}
        <div className="relative z-20 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-white drop-shadow-sm transition-transform hover:scale-105 cursor-default">
              Tulap.id
            </h1>
          </div>

          <button
            type="button"
            onClick={() => setIsOnline((prev) => !prev)}
            className="flex items-center gap-2 rounded-full bg-white/15 backdrop-blur-md px-3.5 py-1.5 text-xs font-semibold text-white border border-white/20 shadow-sm transition hover:bg-white/25 active:scale-95"
            title="Klik untuk simulasi online/offline"
          >
            <span
              className={`h-2.5 w-2.5 rounded-full transition-all ${
                isOnline ? 'bg-[#22c55e] animate-radar shadow-[0_0_8px_#22c55e]' : 'bg-slate-400'
              }`}
            />
            <span>{isOnline ? 'Online' : 'Offline'}</span>
          </button>
        </div>

        {/* HERO TITLE & SUBTITLE */}
        <div className="relative z-20 mt-8 lg:mt-10 max-w-xl">
          <h2 className="text-4xl sm:text-5xl xl:text-[54px] font-black leading-[1.08] tracking-tight text-white">
            Tugas Lapangan <br />
            <span className="text-[#38bdf8] animate-pulse-glow drop-shadow-[0_2px_14px_rgba(56,189,248,0.4)] inline-block">
              dalam Kendali
            </span>
          </h2>
          <p className="mt-4 text-base sm:text-lg text-white/90 font-normal leading-relaxed max-w-lg drop-shadow-sm">
            Dokumentasikan kegiatan, validasi bukti,
            <br className="hidden sm:inline" />
            dan selesaikan laporan dalam satu tempat.
          </p>
        </div>

        {/* CENTER VISUAL: Two Field Officers & Interactive Floating Glass Badges */}
        <div className="relative z-10 w-full mt-6 lg:mt-auto flex items-end justify-center min-h-[340px] sm:min-h-[420px] lg:min-h-[460px]">
          {/* Main Officers Illustration */}
          <div className="relative w-full max-w-[560px] h-[320px] sm:h-[400px] lg:h-[440px]">
            <Image
              src="/hero_illustration_web.png"
              alt="Petugas Lapangan Tulap.id"
              fill
              priority
              className="object-contain object-bottom drop-shadow-[0_20px_40px_rgba(0,0,0,0.25)] pointer-events-none select-none"
            />

            {/* SVG Connecting Dashed Lines with Animated Dash-Flow */}
            <svg
              className="absolute inset-0 w-full h-full pointer-events-none hidden sm:block z-0"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 560 440"
            >
              {/* Connector to Location pin badge */}
              <path
                d="M 270 120 C 275 80, 290 60, 310 50"
                fill="none"
                stroke="rgba(255,255,255,0.8)"
                strokeWidth="2"
                strokeDasharray="6 4"
                className="animate-dash-flow"
              />
              {/* Connector to OCR Struk badge */}
              <path
                d="M 310 50 C 370 40, 400 90, 420 130"
                fill="none"
                stroke="rgba(255,255,255,0.8)"
                strokeWidth="2"
                strokeDasharray="6 4"
                className="animate-dash-flow"
              />
              {/* Connector from OCR to Laporan */}
              <path
                d="M 440 180 C 455 200, 460 220, 465 240"
                fill="none"
                stroke="rgba(255,255,255,0.8)"
                strokeWidth="2"
                strokeDasharray="6 4"
                className="animate-dash-flow"
              />
              {/* Connector from Laporan to Sinkronisasi */}
              <path
                d="M 465 310 C 465 330, 460 345, 455 360"
                fill="none"
                stroke="rgba(255,255,255,0.8)"
                strokeWidth="2"
                strokeDasharray="6 4"
                className="animate-dash-flow"
              />
            </svg>

            {/* 1. FLOATING BADGE: Location Pin (Top above male surveyor's phone) */}
            <div
              onClick={() =>
                setInfoModal({
                  title: 'Geotagging & Validasi Lokasi',
                  body: 'Setiap foto tugas lapangan disematkan data GPS terenkripsi dan diverifikasi anti-fake-GPS secara otomatis.',
                })
              }
              className="absolute left-[54%] top-[2%] -translate-x-1/2 z-20 group cursor-pointer animate-float-slow transition-transform hover:scale-110 active:scale-95"
            >
              <div className="flex h-12 w-12 sm:h-14 sm:w-14 items-center justify-center rounded-2xl bg-white/20 backdrop-blur-md border border-white/40 shadow-[0_8px_24px_rgba(0,0,0,0.18)] ring-2 ring-white/30 transition-all group-hover:bg-white/30 group-hover:shadow-[0_12px_30px_rgba(0,0,0,0.25)]">
                <MapPin className="h-6 w-6 sm:h-7 sm:w-7 text-[#0070f3] fill-[#0070f3] drop-shadow-sm transition-transform group-hover:scale-110" />
              </div>
            </div>

            {/* 2. FLOATING BADGE: OCR Struk / Receipt (Top Right) */}
            <div
              onClick={() =>
                setInfoModal({
                  title: 'OCR Scan Nota Otomatis',
                  body: 'Tulap.id mengekstrak nama merchant, tanggal transaksi, nomor struk, dan total nominal (Rp 206.000) secara otomatis dan instan.',
                })
              }
              className="absolute right-[2%] sm:right-[6%] top-[14%] sm:top-[16%] z-20 group cursor-pointer animate-float-medium transition-all duration-300 hover:scale-110 active:scale-95"
            >
              <div className="relative rounded-2xl bg-white/95 backdrop-blur-md p-2.5 sm:p-3 text-slate-800 shadow-[0_14px_32px_rgba(0,0,0,0.2)] border border-white/70 w-[86px] sm:w-[96px] overflow-hidden group-hover:shadow-[0_18px_36px_rgba(0,0,0,0.25)]">
                {/* Shimmer light effect */}
                <div className="absolute inset-0 pointer-events-none animate-shimmer opacity-40" />

                {/* Green check badge with radar pulse */}
                <div className="absolute -top-1.5 -right-1.5 flex h-5 w-5 sm:h-6 sm:w-6 items-center justify-center rounded-full bg-[#10b981] text-white shadow-md animate-radar">
                  <Check className="h-3 w-3 sm:h-3.5 sm:w-3.5 stroke-[3]" />
                </div>

                <div className="text-[10px] sm:text-[11px] font-bold text-slate-700 tracking-wider text-center border-b border-slate-200/80 pb-1">
                  STRUK
                </div>
                <div className="mt-1.5 space-y-1">
                  <div className="h-1 w-full bg-slate-200 rounded" />
                  <div className="h-1 w-3/4 bg-slate-200 rounded" />
                  <div className="h-1 w-4/5 bg-slate-200 rounded" />
                </div>
                <div className="mt-2 text-[8px] sm:text-[9px] font-semibold text-slate-600 text-center">
                  Total <br />
                  <span className="font-bold text-[#0d52d7]">Rp 206.000</span>
                </div>
              </div>
              <div className="mt-1.5 flex justify-center">
                <span className="rounded-full bg-[#0052d4] px-2.5 py-0.5 text-[9px] sm:text-[10px] font-bold text-white shadow-sm transition-transform group-hover:scale-105">
                  OCR
                </span>
              </div>
            </div>

            {/* 3. FLOATING BADGE: Laporan / Report Document (Middle Right) */}
            <div
              onClick={() =>
                setInfoModal({
                  title: 'Pelaporan Tugas Terverifikasi',
                  body: 'Format LPJ standar instansi otomatis disusun dari catatan kegiatan, foto lokasi anti-fake-GPS, dan scan nota yang tervalidasi.',
                })
              }
              className="absolute right-[0%] sm:right-[4%] top-[48%] sm:top-[50%] z-20 group cursor-pointer animate-float-fast transition-all duration-300 hover:scale-110 active:scale-95"
            >
              <div className="relative rounded-2xl bg-white/95 backdrop-blur-md p-2.5 sm:p-3 text-slate-800 shadow-[0_14px_32px_rgba(0,0,0,0.2)] border border-white/70 w-[86px] sm:w-[96px] overflow-hidden group-hover:shadow-[0_18px_36px_rgba(0,0,0,0.25)]">
                {/* Green check badge with radar pulse */}
                <div className="absolute -top-1.5 -right-1.5 flex h-5 w-5 sm:h-6 sm:w-6 items-center justify-center rounded-full bg-[#10b981] text-white shadow-md animate-radar">
                  <Check className="h-3 w-3 sm:h-3.5 sm:w-3.5 stroke-[3]" />
                </div>

                <div className="text-[10px] sm:text-[11px] font-bold text-slate-700 tracking-wider text-center border-b border-slate-200/80 pb-1">
                  LAPORAN
                </div>
                <div className="mt-1.5 space-y-1">
                  <div className="h-1 w-full bg-slate-200 rounded" />
                  <div className="h-1 w-5/6 bg-slate-200 rounded" />
                  <div className="h-1 w-2/3 bg-slate-200 rounded" />
                </div>
              </div>
            </div>

            {/* 4. FLOATING BADGE: Sinkronisasi Cloud Upload (Bottom Right) */}
            <div
              onClick={() =>
                setInfoModal({
                  title: 'Sinkronisasi Offline-First',
                  body: 'Semua data dan bukti foto tersimpan di penyimpanan lokal saat offline, dan tersinkronisasi otomatis saat terhubung kembali.',
                })
              }
              className="absolute right-[2%] sm:right-[5%] bottom-[4%] sm:bottom-[6%] z-20 group cursor-pointer animate-float-slow transition-all duration-300 hover:scale-110 active:scale-95 flex flex-col items-center"
            >
              <div className="flex h-12 w-12 sm:h-14 sm:w-14 items-center justify-center rounded-2xl bg-[#0055d2]/90 backdrop-blur-md border border-white/40 shadow-[0_12px_28px_rgba(0,0,0,0.22)] text-white group-hover:bg-[#0047b8] group-hover:shadow-[0_16px_34px_rgba(0,0,0,0.28)]">
                <CloudUpload className="h-6 w-6 sm:h-7 sm:w-7 transition-transform group-hover:-translate-y-0.5" />
              </div>
              <span className="mt-1.5 rounded-full bg-[#0052d4] px-2.5 py-0.5 text-[9px] sm:text-[10px] font-bold text-white shadow-sm transition-transform group-hover:scale-105">
                Sinkronisasi
              </span>
            </div>

            {/* 5. FLOATING BADGE: Lokasi Terverifikasi (Bottom Left) */}
            <div
              onClick={() =>
                setInfoModal({
                  title: 'Lokasi Terverifikasi',
                  body: 'Koordinat GPS terkini: -6.200000, 106.816666. Integritas sensor kamera dan lokasi terjamin aman tanpa manipulasi.',
                })
              }
              className="absolute left-[2%] sm:left-[4%] bottom-[4%] sm:bottom-[8%] z-20 group cursor-pointer transition-transform hover:scale-105 active:scale-95"
            >
              <div className="flex items-center gap-2.5 sm:gap-3 rounded-2xl bg-[#0f1e36]/80 backdrop-blur-md border border-white/25 px-3.5 sm:px-4 py-2 sm:py-2.5 shadow-[0_14px_32px_rgba(0,0,0,0.28)] text-white group-hover:bg-[#0f1e36]/90">
                <div className="flex h-7 w-7 sm:h-8 sm:w-8 shrink-0 items-center justify-center rounded-full bg-[#10b981] text-white shadow-sm animate-radar">
                  <Check className="h-4 w-4 sm:h-4.5 sm:w-4.5 stroke-[3]" />
                </div>
                <div>
                  <div className="text-xs sm:text-sm font-bold text-white leading-tight">
                    Lokasi Terverifikasi
                  </div>
                  <div className="text-[10px] sm:text-xs text-emerald-300 font-mono tracking-tight mt-0.5">
                    -6.200000, 106.816666
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* =========================================================================
          RIGHT COLUMN: FLOATING CLEAN LOGIN CARD (Matching Web Reference)
          ========================================================================= */}
      <section className="relative w-full lg:w-[44%] xl:w-[42%] flex items-center justify-center p-6 sm:p-10 lg:p-12 bg-[#f4f7fb]">
        {/* Subtle Topographic Contours & Dot Grid on the Right */}
        <div className="absolute inset-0 pointer-events-none opacity-40">
          <svg className="w-full h-full" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="none" viewBox="0 0 600 800">
            <path
              d="M-20,100 C150,40 300,180 620,80 M-20,240 C180,180 340,300 620,200 M-20,400 C140,320 320,440 620,340 M-20,560 C200,480 380,600 620,500 M-20,700 C160,640 350,760 620,680"
              fill="none"
              stroke="#0d52d7"
              strokeWidth="0.8"
              opacity="0.12"
            />
          </svg>
        </div>

        {/* Centered Floating White Login Card */}
        <div className="relative z-10 w-full max-w-[460px] rounded-[32px] bg-white p-7 sm:p-10 shadow-[0_20px_60px_rgba(15,75,167,0.08)] border border-slate-100/90 transition-all">
          {/* Top Tulap Emblem Badge */}
          <div className="flex justify-center">
            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-[#edf4ff] text-[#0d52d7] shadow-inner ring-4 ring-[#f4f8ff]">
              <Image
                src="/logo.png"
                alt="Tulap.id Emblem"
                width={30}
                height={30}
                className="object-contain"
              />
            </div>
          </div>

          {/* Heading */}
          <h2 className="mt-4 text-center text-3xl sm:text-[34px] font-extrabold tracking-tight text-[#0f1e36]">
            Masuk
          </h2>
          <p className="mt-2 text-center text-sm text-slate-500 font-normal leading-relaxed">
            Masuk untuk melanjutkan tugas lapangan Anda.
          </p>

          {/* Register Link */}
          <p className="mt-1.5 text-center text-sm text-slate-500">
            Belum memiliki akun?{' '}
            <button
              type="button"
              onClick={() => setInfoModal({ title: 'Pendaftaran Akun', body: REGISTER_TEXT })}
              className="font-bold text-[#0d52d7] hover:underline focus:outline-none"
            >
              Daftar
            </button>
          </p>

          {/* Form */}
          <form onSubmit={handleSubmit} className="mt-7 space-y-4">
            {/* EMAIL */}
            <div className="space-y-1.5">
              <label htmlFor="login-email" className="block text-sm font-bold text-slate-800">
                Email
              </label>
              <div className="relative">
                <Mail className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
                <input
                  id="login-email"
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Masukkan email"
                  className="w-full rounded-2xl border border-slate-200 bg-white py-3.5 pl-11 pr-4 text-sm text-slate-900 placeholder:text-slate-400 outline-none transition focus:border-[#0d52d7] focus:ring-4 focus:ring-[#dfeafc]"
                />
              </div>
            </div>

            {/* PASSWORD */}
            <div className="space-y-1.5">
              <label htmlFor="login-password" className="block text-sm font-bold text-slate-800">
                Kata Sandi
              </label>
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 h-5 w-5 -translate-y-1/2 text-slate-400" />
                <input
                  id="login-password"
                  type={showPassword ? 'text' : 'password'}
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Masukkan kata sandi"
                  className="w-full rounded-2xl border border-slate-200 bg-white py-3.5 pl-11 pr-11 text-sm text-slate-900 placeholder:text-slate-400 outline-none transition focus:border-[#0d52d7] focus:ring-4 focus:ring-[#dfeafc]"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((s) => !s)}
                  className="absolute right-3.5 top-1/2 -translate-y-1/2 p-1 text-slate-400 transition hover:text-slate-700"
                  aria-label={showPassword ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'}
                  tabIndex={-1}
                >
                  {showPassword ? <EyeOff className="h-5 w-5" /> : <Eye className="h-5 w-5" />}
                </button>
              </div>

              {/* Lupa Kata Sandi */}
              <div className="flex justify-end pt-1">
                <button
                  type="button"
                  onClick={() => setShowForgotPassword(true)}
                  className="text-xs sm:text-sm font-semibold text-[#0d52d7] hover:underline"
                >
                  Lupa kata sandi?
                </button>
              </div>
            </div>

            {/* Error Message */}
            {error && (
              <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 p-3 text-xs sm:text-sm text-red-600 animate-in fade-in duration-200">
                <AlertCircle className="h-4 w-4 shrink-0" />
                <span>{error}</span>
              </div>
            )}

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isSubmitting}
              className="mt-2 flex w-full items-center justify-center rounded-2xl bg-[#0d52d7] py-3.5 text-base font-bold text-white shadow-[0_8px_20px_rgba(13,82,215,0.28)] transition-all hover:bg-[#0b45b5] hover:shadow-[0_12px_24px_rgba(13,82,215,0.35)] active:scale-[0.99] disabled:opacity-60"
            >
              {isSubmitting ? 'Memproses...' : 'Masuk'}
            </button>
          </form>

          {/* Divider & Social Login */}
          <div className="mt-6">
            <SocialLoginButtons onError={setError} />
          </div>

          {/* Need Help Link */}
          <div className="mt-6 text-center">
            <button
              type="button"
              onClick={() => setInfoModal({ title: 'Bantuan Masuk', body: HELP_TEXT })}
              className="text-xs sm:text-sm font-semibold text-[#0d52d7] hover:underline"
            >
              Butuh bantuan masuk?
            </button>
          </div>

          {/* Terms & Privacy Footer */}
          <div className="mt-6 text-center text-[11.5px] leading-relaxed text-slate-500">
            Dengan masuk, Anda menyetujui{' '}
            <button
              type="button"
              onClick={() => setInfoModal({ title: 'Syarat Penggunaan', body: TERMS_TEXT })}
              className="font-semibold text-[#0d52d7] hover:underline"
            >
              Syarat Penggunaan
            </button>{' '}
            dan{' '}
            <button
              type="button"
              onClick={() => setInfoModal({ title: 'Kebijakan Privasi', body: PRIVACY_TEXT })}
              className="font-semibold text-[#0d52d7] hover:underline"
            >
              Kebijakan Privasi
            </button>{' '}
            Tulap.id.
          </div>
        </div>
      </section>

      {/* MODALS */}
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
    </main>
  );
}
