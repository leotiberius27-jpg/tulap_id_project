import { NextRequest, NextResponse } from 'next/server';
import { ACCESS_TOKEN_COOKIE } from '@/lib/session';

/// middleware
/// ----------------------------------------------------------------------
/// Penjaga rute sederhana: hanya memeriksa KEBERADAAN cookie token
/// (bukan validitas JWT-nya - itu tugas backend di setiap request API),
/// cukup untuk mencegah halaman dashboard dirender untuk pengguna yang
/// jelas belum login, tanpa menduplikasi logika verifikasi JWT di sini.
/// ----------------------------------------------------------------------
export function middleware(request: NextRequest) {
  const hasSession = request.cookies.has(ACCESS_TOKEN_COOKIE);
  const { pathname } = request.nextUrl;

  if (!hasSession && (pathname.startsWith('/tasks') || pathname.startsWith('/employees'))) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  if (hasSession && pathname === '/login') {
    return NextResponse.redirect(new URL('/tasks', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/tasks/:path*', '/employees/:path*', '/login'],
};
