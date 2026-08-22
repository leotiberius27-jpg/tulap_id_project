'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Search, SlidersHorizontal, Plus } from 'lucide-react';
import Link from 'next/link';
import { NotificationBell } from './notification-bell';

interface TopHeaderProps {
  userRole?: string;
}

export function TopHeader({ userRole }: TopHeaderProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [query, setQuery] = useState(searchParams.get('q') || '');
  const [currentDate, setCurrentDate] = useState<string>('');
  const isAdmin = userRole === 'ADMIN' || userRole === 'SUPER_ADMIN';

  useEffect(() => {
    // Format tanggal Indonesia dinamis pada sisi client
    const formatted = new Intl.DateTimeFormat('id-ID', {
      weekday: 'long',
      day: 'numeric',
      month: 'long',
      year: 'numeric',
    }).format(new Date());
    setCurrentDate(formatted);
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    if (!query.trim()) {
      router.push('/tasks');
    } else {
      router.push(`/tasks?q=${encodeURIComponent(query.trim())}`);
    }
  };

  return (
    <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-6 border-b border-border">
      {/* Date display matching reference top right */}
      <div className="flex items-center gap-2">
        <p className="text-small font-semibold text-text-primary capitalize min-h-[20px]" suppressHydrationWarning>
          {currentDate}
        </p>
      </div>

      {/* Action and Search Controls */}
      <div className="flex items-center gap-3">
        <form onSubmit={handleSearch} className="relative">
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Cari tugas, pegawai, nota..."
            className="w-64 lg:w-80 pl-9 pr-4 py-2 text-small bg-surface border border-border rounded-button text-text-primary placeholder:text-text-secondary/70 focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary shadow-sm transition"
          />
          <Search className="w-4 h-4 text-text-secondary absolute left-3 top-1/2 -translate-y-1/2" />
        </form>

        <button
          type="button"
          aria-label="Filter lanjutan"
          className="p-2 text-text-secondary hover:text-text-primary bg-surface border border-border rounded-button shadow-sm hover:bg-background transition"
        >
          <SlidersHorizontal className="w-4 h-4" />
        </button>

        <NotificationBell />

        {isAdmin && (
          <Link
            href="/tasks/new"
            className="flex items-center gap-1.5 px-3.5 py-2 bg-primary hover:bg-primary-hover text-white text-small font-medium rounded-button shadow-sm transition"
          >
            <Plus className="w-4 h-4" />
            <span className="hidden sm:inline">Buat Tugas</span>
          </Link>
        )}
      </div>
    </div>
  );
}
