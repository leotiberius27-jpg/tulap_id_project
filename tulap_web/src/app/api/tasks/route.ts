import { NextResponse } from 'next/server';
import { apiFetch, ApiError } from '@/lib/api';

export async function POST(request: Request) {
  const body = await request.json();
  try {
    const task = await apiFetch('/tasks', {
      method: 'POST',
      body: JSON.stringify(body),
    });
    return NextResponse.json(task, { status: 201 });
  } catch (error) {
    if (error instanceof ApiError) {
      return NextResponse.json({ message: error.message }, { status: error.status });
    }
    throw error;
  }
}
