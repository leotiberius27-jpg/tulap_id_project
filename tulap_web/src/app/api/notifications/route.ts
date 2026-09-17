import { NextResponse } from 'next/server';
import { apiFetch, ApiError } from '@/lib/api';
import { NotificationListResponse } from '@/lib/types';

export async function GET(request: Request) {
  const url = new URL(request.url);
  const qs = url.searchParams.toString();
  try {
    const data = await apiFetch<NotificationListResponse>(
      `/notifications${qs ? `?${qs}` : ''}`,
    );
    return NextResponse.json(data);
  } catch (error) {
    if (error instanceof ApiError) {
      return NextResponse.json({ message: error.message }, { status: error.status });
    }
    throw error;
  }
}
