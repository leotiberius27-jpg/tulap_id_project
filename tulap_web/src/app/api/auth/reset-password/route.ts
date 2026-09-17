import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_API_URL ?? 'http://localhost:3000';

/// POST /api/auth/reset-password
/// ----------------------------------------------------------------------
/// Langkah 2 alur "Lupa Kata Sandi" — menukar kode OTP 6-digit yang
/// dikirim ke email dengan kata sandi baru. Backend memvalidasi kode
/// (hash-compare, kedaluwarsa mengikuti RESET_CODE_TTL_MINUTES) dan
/// menolak dengan 401 kalau salah/sudah lewat waktu.
/// ----------------------------------------------------------------------
export async function POST(request: Request) {
  const { email, code, newPassword } = await request.json();

  const backendResponse = await fetch(`${BACKEND_URL}/auth/reset-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, code, newPassword }),
  });

  const data = await backendResponse.json().catch(() => ({}));

  if (!backendResponse.ok) {
    return NextResponse.json(
      { message: data.message ?? 'Kode reset tidak valid atau telah kedaluwarsa.' },
      { status: backendResponse.status },
    );
  }

  return NextResponse.json(data);
}
