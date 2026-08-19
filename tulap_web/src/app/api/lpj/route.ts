import { NextResponse } from 'next/server';
import { apiFetchBinary, ApiError } from '@/lib/api';

export async function POST(request: Request) {
  const { taskId } = await request.json();

  try {
    const { buffer, fileName, contentType } = await apiFetchBinary('/lpj/generate', {
      method: 'POST',
      body: JSON.stringify({ taskId }),
    });

    return new NextResponse(buffer, {
      headers: {
        'Content-Type': contentType,
        'Content-Disposition': `attachment; filename="${fileName}"`,
      },
    });
  } catch (error) {
    if (error instanceof ApiError) {
      return NextResponse.json({ message: error.message }, { status: error.status });
    }
    throw error;
  }
}
