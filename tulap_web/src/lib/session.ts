import { cookies } from 'next/headers';

export const ACCESS_TOKEN_COOKIE = 'tulap_access_token';
export const REFRESH_TOKEN_COOKIE = 'tulap_refresh_token';
export const USER_COOKIE = 'tulap_user';

export type SessionUser = {
  id: string;
  fullName: string;
  email: string;
  role: 'PEGAWAI' | 'VERIFIKATOR' | 'ADMIN' | 'SUPER_ADMIN';
  instansiName: string;
};

export type Session = {
  accessToken: string;
  refreshToken: string;
  user: SessionUser;
};

const COOKIE_OPTIONS = {
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'lax' as const,
  path: '/',
};

/// setSession
/// ----------------------------------------------------------------------
/// Token & profil user disimpan di cookie httpOnly, TIDAK PERNAH di
/// localStorage/sessionStorage - mencegah pencurian token lewat XSS
/// (halaman client tidak pernah punya akses baca ke token sama sekali,
/// semua panggilan API backend dilakukan lewat Route Handler
/// server-side yang membaca cookie ini).
/// ----------------------------------------------------------------------
export async function setSession(session: Session) {
  const cookieStore = await cookies();
  cookieStore.set(ACCESS_TOKEN_COOKIE, session.accessToken, {
    ...COOKIE_OPTIONS,
    maxAge: 60 * 15, // selaras JWT_ACCESS_EXPIRES_IN default backend (15m)
  });
  cookieStore.set(REFRESH_TOKEN_COOKIE, session.refreshToken, {
    ...COOKIE_OPTIONS,
    maxAge: 60 * 60 * 24 * 7, // selaras JWT_REFRESH_EXPIRES_IN default backend (7d)
  });
  cookieStore.set(USER_COOKIE, JSON.stringify(session.user), {
    ...COOKIE_OPTIONS,
    maxAge: 60 * 60 * 24 * 7,
  });
}

export async function clearSession() {
  const cookieStore = await cookies();
  cookieStore.delete(ACCESS_TOKEN_COOKIE);
  cookieStore.delete(REFRESH_TOKEN_COOKIE);
  cookieStore.delete(USER_COOKIE);
}

export async function getSession(): Promise<Session | null> {
  const cookieStore = await cookies();
  const accessToken = cookieStore.get(ACCESS_TOKEN_COOKIE)?.value;
  const refreshToken = cookieStore.get(REFRESH_TOKEN_COOKIE)?.value;
  const userRaw = cookieStore.get(USER_COOKIE)?.value;

  if (!accessToken || !refreshToken || !userRaw) {
    return null;
  }

  try {
    const user = JSON.parse(userRaw) as SessionUser;
    return { accessToken, refreshToken, user };
  } catch {
    return null;
  }
}
