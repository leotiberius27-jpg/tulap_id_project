import { NextResponse } from 'next/server';
import { setSession } from '@/lib/session';

const BACKEND_URL = process.env.BACKEND_API_URL ?? 'http://localhost:3000';

/// POST /api/auth/apple
/// ----------------------------------------------------------------------
/// Menerima identityToken (+ fullName opsional, hanya ada di respons
/// Apple pada sign-in PERTAMA KALI) dari AppleSignInButton, meneruskan
/// ke backend untuk verifikasi JWKS Apple. Pola sesi & guard PEGAWAI
/// sama dengan /api/auth/login dan /api/auth/google.
/// ----------------------------------------------------------------------
export async function POST(request: Request) {
  const { identityToken, fullName } = await request.json();

  const backendResponse = await fetch(`${BACKEND_URL}/auth/apple`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identityToken, fullName }),
  });

  const data = await backendResponse.json().catch(() => ({}));

  if (!backendResponse.ok) {
    return NextResponse.json(
      { message: data.message ?? 'Masuk dengan Apple gagal.' },
      { status: backendResponse.status },
    );
  }

  if (data.user.role === 'PEGAWAI') {
    return NextResponse.json(
      {
        message:
          'Akun Pegawai lapangan hanya bisa login lewat aplikasi mobile Tulap.id, bukan Dashboard ini.',
      },
      { status: 403 },
    );
  }

  await setSession({
    accessToken: data.accessToken,
    refreshToken: data.refreshToken,
    user: data.user,
  });

  return NextResponse.json({ user: data.user });
}
