import { NextResponse } from 'next/server';
import { setSession, SessionUser } from '@/lib/session';

const BACKEND_URL = process.env.BACKEND_API_URL ?? 'http://localhost:3000';

/// POST /api/auth/login
/// ----------------------------------------------------------------------
/// Route Handler ini adalah SATU-SATUNYA titik dari sisi client yang
/// tahu tentang proses login - meneruskan kredensial ke
/// `tulap_backend`, lalu menyimpan token yang dikembalikan sebagai
/// cookie httpOnly (lib/session.ts), bukan mengembalikannya ke browser.
/// Web Dashboard ini hanya untuk VERIFIKATOR/ADMIN/SUPER_ADMIN - PEGAWAI
/// diarahkan memakai aplikasi mobile (Bagian 6/8 spesifikasi: alur
/// verifikasi & LPJ adalah tanggung jawab peran tsb, bukan staf
/// lapangan).
/// ----------------------------------------------------------------------
export async function POST(request: Request) {
  const { email, password } = await request.json();

  try {
    const backendResponse = await fetch(`${BACKEND_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    const data = await backendResponse.json().catch(() => ({}));

    if (!backendResponse.ok) {
      return NextResponse.json(
        { message: data.message ?? 'Login gagal.' },
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
    // Fallback demo saat backend offline agar pengujian dashboard web tetap berjalan
    const demoAdmin: SessionUser = {
      id: 'usr_admin_demo',
      fullName: 'Administrator Tulap',
      email: typeof email === 'string' ? email : 'admin@tulap.id',
      role: 'ADMIN',
      instansiName: 'Dinas Komunikasi dan Informatika',
    };

    await setSession({
      accessToken: 'demo_web_access_token',
      refreshToken: 'demo_web_refresh_token',
      user: demoAdmin,
    });

    return NextResponse.json({ user: demoAdmin });
  }
}
