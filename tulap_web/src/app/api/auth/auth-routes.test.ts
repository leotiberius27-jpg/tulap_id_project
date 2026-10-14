import { beforeEach, describe, expect, it, vi } from 'vitest';

// setSession menulis cookie lewat next/headers - di-mock supaya test bisa
// memastikan TIDAK ADA sesi yang dibuat di jalur gagal.
const setSession = vi.fn();
vi.mock('@/lib/session', () => ({ setSession: (...args: unknown[]) => setSession(...args) }));

import { POST as loginPOST } from './login/route';
import { POST as googlePOST } from './google/route';
import { POST as applePOST } from './apple/route';

/// Regression test P0-02: sebelum perbaikan, ketiga route membuat sesi
/// ADMIN "demo" (token palsu) setiap kali fetch ke backend gagal ATAU
/// respons backend tidak berbentuk seperti yang diharapkan.
const routes = [
  {
    name: '/api/auth/login',
    POST: loginPOST,
    body: { email: 'admin@tulap.id', password: 'rahasia' },
    backendPath: '/auth/login',
  },
  {
    name: '/api/auth/google',
    POST: googlePOST,
    body: { idToken: 'google-id-token' },
    backendPath: '/auth/google',
  },
  {
    name: '/api/auth/apple',
    POST: applePOST,
    body: { identityToken: 'apple-identity-token', fullName: 'Budi' },
    backendPath: '/auth/apple',
  },
];

const validAdminPayload = {
  accessToken: 'access-from-backend',
  refreshToken: 'refresh-from-backend',
  user: {
    id: 'usr_1',
    fullName: 'Admin PU',
    email: 'admin@tulap.id',
    role: 'ADMIN',
    instansiName: 'Dinas PU',
  },
};

const fetchMock = vi.fn();

function request(body: unknown) {
  return new Request('http://localhost/api/auth', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function backendReplies(status: number, body: unknown) {
  fetchMock.mockResolvedValue(
    new Response(JSON.stringify(body), {
      status,
      headers: { 'Content-Type': 'application/json' },
    }),
  );
}

beforeEach(() => {
  setSession.mockReset();
  fetchMock.mockReset();
  vi.stubGlobal('fetch', fetchMock);
});

describe.each(routes)('$name', ({ POST, body, backendPath }) => {
  it('backend tidak dapat dihubungi -> 503, tanpa sesi/token/role palsu', async () => {
    fetchMock.mockRejectedValue(new TypeError('fetch failed'));

    const response = await POST(request(body));
    const json = await response.json();

    expect(response.status).toBe(503);
    expect(json.user).toBeUndefined();
    expect(JSON.stringify(json)).not.toMatch(/demo|token/i);
    expect(setSession).not.toHaveBeenCalled();
  });

  it('backend 2xx tanpa user/token -> 502, tanpa sesi', async () => {
    backendReplies(200, { message: 'ok' });

    const response = await POST(request(body));

    expect(response.status).toBe(502);
    expect(setSession).not.toHaveBeenCalled();
  });

  it('backend 2xx dengan role tidak dikenal -> 502, tanpa sesi', async () => {
    backendReplies(200, {
      ...validAdminPayload,
      user: { ...validAdminPayload.user, role: 'ROOT' },
    });

    const response = await POST(request(body));

    expect(response.status).toBe(502);
    expect(setSession).not.toHaveBeenCalled();
  });

  it('backend menolak kredensial -> status & pesan backend diteruskan, tanpa sesi', async () => {
    backendReplies(401, { message: 'Email atau kata sandi salah.' });

    const response = await POST(request(body));
    const json = await response.json();

    expect(response.status).toBe(401);
    expect(json.message).toBe('Email atau kata sandi salah.');
    expect(setSession).not.toHaveBeenCalled();
  });

  it('akun PEGAWAI -> 403, tanpa sesi (tetap diarahkan ke mobile)', async () => {
    backendReplies(200, {
      ...validAdminPayload,
      user: { ...validAdminPayload.user, role: 'PEGAWAI' },
    });

    const response = await POST(request(body));

    expect(response.status).toBe(403);
    expect(setSession).not.toHaveBeenCalled();
  });

  it('role dikirim client tidak diteruskan ke backend (role escalation)', async () => {
    backendReplies(200, validAdminPayload);

    await POST(request({ ...body, role: 'SUPER_ADMIN', user: { role: 'SUPER_ADMIN' } }));

    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toMatch(new RegExp(`${backendPath}$`));
    expect(JSON.parse(init.body)).toEqual(body);
  });

  it('login sah -> sesi memakai token & user PERSIS dari backend', async () => {
    backendReplies(200, validAdminPayload);

    const response = await POST(request(body));
    const json = await response.json();

    expect(response.status).toBe(200);
    expect(json.user).toEqual(validAdminPayload.user);
    expect(setSession).toHaveBeenCalledTimes(1);
    expect(setSession).toHaveBeenCalledWith(validAdminPayload);
  });

  it('kegagalan menyimpan sesi tidak dialihkan menjadi sesi pengganti', async () => {
    backendReplies(200, validAdminPayload);
    setSession.mockRejectedValueOnce(new Error('cookie store unavailable'));

    await expect(POST(request(body))).rejects.toThrow('cookie store unavailable');
    expect(setSession).toHaveBeenCalledTimes(1);
  });
});
