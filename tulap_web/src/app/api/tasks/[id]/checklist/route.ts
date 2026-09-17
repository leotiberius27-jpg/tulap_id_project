import { NextResponse } from 'next/server';
import { apiFetch, ApiError } from '@/lib/api';

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const body = await request.json();
  try {
    const items = await apiFetch(`/tasks/${id}/checklist`, {
      method: 'POST',
      body: JSON.stringify(body),
    });
    return NextResponse.json(items, { status: 201 });
  } catch (error) {
    if (error instanceof ApiError) {
      return NextResponse.json({ message: error.message }, { status: error.status });
    }
    throw error;
  }
}
