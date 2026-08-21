import { NextResponse } from 'next/server';
import { apiFetch, ApiError } from '@/lib/api';

export async function PATCH(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  try {
    const notification = await apiFetch(`/notifications/${id}/read`, { method: 'PATCH' });
    return NextResponse.json(notification);
  } catch (error) {
    if (error instanceof ApiError) {
      return NextResponse.json({ message: error.message }, { status: error.status });
    }
    throw error;
  }
}
