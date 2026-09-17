import { NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_API_URL ?? 'http://localhost:3000';

/// POST /api/auth/forgot-password
/// ----------------------------------------------------------------------
/// Langkah 1 alur "Lupa Kata Sandi" — meneruskan email ke backend, yang
/// akan mengirim kode OTP 6-digit lewat SMTP jika email terdaftar.
/// Backend SENGAJA selalu membalas pesan sukses yang sama baik email
/// terdaftar maupun tidak (mencegah orang menebak-nebak email pengguna
/// yang valid), jadi Route Handler ini pun tidak membedakan keduanya.
/// ----------------------------------------------------------------------
export async function POST(request: Request) {
  const { email } = await request.json();

  const backendResponse = await fetch(`${BACKEND_URL}/auth/forgot-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email }),
  });

  const data = await backendResponse.json().catch(() => ({}));

  if (!backendResponse.ok) {
    return NextResponse.json(
      { message: data.message ?? 'Gagal memproses permintaan.' },
      { status: backendResponse.status },
    );
  }

  return NextResponse.json(data);
}
