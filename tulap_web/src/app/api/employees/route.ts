import { NextResponse } from 'next/server';
import { apiFetch, ApiError } from '@/lib/api';

/// POST /api/employees
/// ----------------------------------------------------------------------
/// Proxy ke `POST /auth/register` backend, BUKAN `/users` - pembuatan
/// user baru sengaja terikat ke AuthController (lihat komentar di
/// tulap_backend/src/modules/users/users.controller.ts), jadi endpoint
/// ini hanya menamai ulang jalurnya agar sesuai konteks "Pegawai" di
/// dashboard tanpa mengubah alur backend.
/// ----------------------------------------------------------------------
export async function POST(request: Request) {
  const body = await request.json();
  try {
    const employee = await apiFetch('/auth/register', {
      method: 'POST',
      body: JSON.stringify(body),
    });
    return NextResponse.json(employee, { status: 201 });
  } catch (error) {
    if (error instanceof ApiError) {
      return NextResponse.json({ message: error.message }, { status: error.status });
    }
    throw error;
  }
}
