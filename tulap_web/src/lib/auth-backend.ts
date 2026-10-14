import { NextResponse } from 'next/server';
import { SessionUser } from './session';

const SESSION_ROLES: readonly SessionUser['role'][] = [
  'PEGAWAI',
  'VERIFIKATOR',
  'ADMIN',
  'SUPER_ADMIN',
];

export type BackendSessionPayload = {
  accessToken: string;
  refreshToken: string;
  user: SessionUser;
};

/// authBackendUnavailable
/// ----------------------------------------------------------------------
/// Dipakai /api/auth/{login,google,apple} saat backend TIDAK dapat
/// dihubungi. Gagal tertutup (fail-closed): TIDAK PERNAH membuat sesi,
/// token, atau role pengganti - sebelumnya ketiga route membuat sesi
/// ADMIN "demo" di kondisi ini, sehingga dashboard admin terbuka untuk
/// kredensial apa pun selama backend down.
/// ----------------------------------------------------------------------
export function authBackendUnavailable() {
  return NextResponse.json(
    {
      message:
        'Server Tulap.id sedang tidak dapat dihubungi. Silakan coba beberapa saat lagi.',
    },
    { status: 503 },
  );
}

/// Respons 2xx dari backend yang bentuknya tidak sesuai kontrak login
/// (tanpa token / user / role yang dikenal) - ditolak, bukan dilanjutkan
/// menjadi sesi setengah jadi.
export function authBackendInvalidResponse() {
  return NextResponse.json(
    { message: 'Respons server tidak valid. Silakan coba lagi.' },
    { status: 502 },
  );
}

export function isBackendSessionPayload(data: unknown): data is BackendSessionPayload {
  if (!data || typeof data !== 'object') return false;
  const { accessToken, refreshToken, user } = data as Record<string, unknown>;
  if (typeof accessToken !== 'string' || accessToken.length === 0) return false;
  if (typeof refreshToken !== 'string' || refreshToken.length === 0) return false;
  if (!user || typeof user !== 'object') return false;
  const { id, role } = user as Record<string, unknown>;
  return (
    typeof id === 'string' &&
    id.length > 0 &&
    SESSION_ROLES.includes(role as SessionUser['role'])
  );
}
