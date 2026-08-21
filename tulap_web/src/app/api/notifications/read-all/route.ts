import { NextResponse } from 'next/server';
import { apiFetch, ApiError } from '@/lib/api';

export async function PATCH() {
  try {
    const result = await apiFetch('/notifications/read-all', { method: 'PATCH' });
    return NextResponse.json(result);
  } catch (error) {
    if (error instanceof ApiError) {
      return NextResponse.json({ message: error.message }, { status: error.status });
    }
    throw error;
  }
}
