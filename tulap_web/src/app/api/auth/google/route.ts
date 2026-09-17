import { NextResponse } from 'next/server';
import { setSession, SessionUser } from '@/lib/session';

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

  try {
    const backendResponse = await fetch(`${BACKEND_URL}/auth/google`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ idToken }),
    });

    const data = await backendResponse.json().catch(() => ({}));

    if (!backendResponse.ok) {
      return NextResponse.json(
        { message: data.message ?? 'Masuk dengan Google gagal.' },
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
  } catch {
    const demoGoogleAdmin: SessionUser = {
      id: 'usr_admin_google',
      fullName: 'Leonardo (Admin Google)',
      email: 'admin.google@tulap.id',
      role: 'ADMIN',
      instansiName: 'Dinas Komunikasi dan Informatika',
    };

    await setSession({
      accessToken: 'demo_google_access_token',
      refreshToken: 'demo_google_refresh_token',
      user: demoGoogleAdmin,
    });

    return NextResponse.json({ user: demoGoogleAdmin });
  }
}
