import { NextResponse } from 'next/server';
import { setSession } from '@/lib/session';
import {
  authBackendInvalidResponse,
  authBackendUnavailable,
  isBackendSessionPayload,
} from '@/lib/auth-backend';

const BACKEND_URL = process.env.BACKEND_API_URL ?? 'http://localhost:3000';

/// POST /api/auth/google
/// ----------------------------------------------------------------------
/// Menerima idToken dari Google Identity Services (didapat client-side
/// di GoogleSignInButton), meneruskannya ke backend untuk diverifikasi
/// tanda tangannya (OAuthVerifierService — TIDAK PERNAH dipercaya
/// mentah-mentah dari browser). Pola sesi & guard PEGAWAI sama persis
/// dengan /api/auth/login, supaya perilaku dashboard konsisten terlepas
/// dari metode masuknya.
/// ----------------------------------------------------------------------
export async function POST(request: Request) {
  const { idToken } = await request.json();

  // HANYA kegagalan jaringan ke backend yang ditangkap di sini - tidak
  // ada sesi pengganti yang dibuat (lihat lib/auth-backend.ts).
  let backendResponse: Response;
  try {
    backendResponse = await fetch(`${BACKEND_URL}/auth/google`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ idToken }),
    });
  } catch {
    return authBackendUnavailable();
  }

  const data = await backendResponse.json().catch(() => ({}));

  if (!backendResponse.ok) {
    return NextResponse.json(
      { message: data.message ?? 'Masuk dengan Google gagal.' },
      { status: backendResponse.status },
    );
  }

  if (!isBackendSessionPayload(data)) {
    return authBackendInvalidResponse();
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
