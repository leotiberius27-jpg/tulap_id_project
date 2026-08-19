import { NextResponse } from 'next/server';
import { apiFetch, ApiError } from '@/lib/api';

export async function POST(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  try {
    const task = await apiFetch(`/tasks/${id}/approve`, { method: 'POST' });
    return NextResponse.json(task);
  } catch (error) {
    if (error instanceof ApiError) {
      return NextResponse.json({ message: error.message }, { status: error.status });
    }
    throw error;
  }
}
