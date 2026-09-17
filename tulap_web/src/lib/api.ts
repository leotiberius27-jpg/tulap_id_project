import { getSession } from './session';

const BACKEND_URL = process.env.BACKEND_API_URL ?? 'http://localhost:3000';

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
  ) {
    super(message);
  }
}

/// apiFetch
/// ----------------------------------------------------------------------
/// SATU-SATUNYA jalur Server Component/Route Handler memanggil
/// tulap_backend - selalu menyisipkan Authorization header dari sesi
/// cookie httpOnly (lihat session.ts), tidak pernah dipanggil dari
/// client component langsung (browser tidak pernah tahu BACKEND_API_URL
/// maupun access token).
/// ----------------------------------------------------------------------
export async function apiFetch<T>(
  path: string,
  init?: RequestInit,
): Promise<T> {
  const session = await getSession();

  const response = await fetch(`${BACKEND_URL}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(session ? { Authorization: `Bearer ${session.accessToken}` } : {}),
      ...init?.headers,
    },
    cache: 'no-store',
  });

  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new ApiError(
      body.message ?? `Permintaan ke backend gagal (${response.status}).`,
      response.status,
    );
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return response.json() as Promise<T>;
}

/// apiFetchBinary
/// ----------------------------------------------------------------------
/// Untuk endpoint yang mengembalikan file biner, bukan JSON (mis.
/// POST /lpj/generate yang mengembalikan PDF) - lihat lpj.controller.ts
/// backend yang mengirim Content-Type: application/pdf langsung.
/// ----------------------------------------------------------------------
export async function apiFetchBinary(
  path: string,
  init?: RequestInit,
): Promise<{ buffer: ArrayBuffer; fileName: string; contentType: string }> {
  const session = await getSession();

  const response = await fetch(`${BACKEND_URL}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(session ? { Authorization: `Bearer ${session.accessToken}` } : {}),
      ...init?.headers,
    },
    cache: 'no-store',
  });

  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new ApiError(
      body.message ?? `Permintaan ke backend gagal (${response.status}).`,
      response.status,
    );
  }

  const disposition = response.headers.get('content-disposition') ?? '';
  const match = disposition.match(/filename="?([^"]+)"?/);

  return {
    buffer: await response.arrayBuffer(),
    fileName: match?.[1] ?? 'dokumen.pdf',
    contentType: response.headers.get('content-type') ?? 'application/octet-stream',
  };
}
