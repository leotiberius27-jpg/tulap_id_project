'use client';

import { useEffect, useRef, useState } from 'react';
import Link from 'next/link';
import { AppNotification, NotificationListResponse } from '@/lib/types';

const POLL_INTERVAL_MS = 60_000;

const dateFormatter = new Intl.DateTimeFormat('id-ID', {
  day: '2-digit',
  month: 'short',
  hour: '2-digit',
  minute: '2-digit',
});

export function NotificationBell() {
  const [items, setItems] = useState<AppNotification[]>([]);
  const [unreadCount, setUnreadCount] = useState(0);
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  async function load() {
    try {
      const response = await fetch('/api/notifications?pageSize=10');
      if (!response.ok) return;
      const data: NotificationListResponse = await response.json();
      setItems(data.items);
      setUnreadCount(data.meta.unreadCount);
    } catch {
      // Diam-diam gagal - notifikasi bukan fitur kritis, tidak boleh
      // memblokir/mengganggu tampilan dashboard jika sedang offline.
    }
  }

  useEffect(() => {
    // Fetch-on-mount + poll pattern: `load()` is async, so its setState
    // calls happen in a later microtask, not synchronously during this
    // effect - unavoidable for client-fetched data with no server-passed
    // initial value (unlike the rest of the dashboard, which fetches via
    // Server Components).
    // eslint-disable-next-line react-hooks/set-state-in-effect
    load();
    const interval = setInterval(load, POLL_INTERVAL_MS);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  async function markRead(id: string) {
    setItems((prev) => prev.map((n) => (n.id === id ? { ...n, isRead: true } : n)));
    setUnreadCount((prev) => Math.max(0, prev - 1));
    await fetch(`/api/notifications/${id}/read`, { method: 'PATCH' });
  }

  async function markAllRead() {
    setItems((prev) => prev.map((n) => ({ ...n, isRead: true })));
    setUnreadCount(0);
    await fetch('/api/notifications/read-all', { method: 'PATCH' });
  }

  return (
    <div className="relative" ref={containerRef}>
      <button
        onClick={() => setIsOpen((prev) => !prev)}
        className="relative flex h-10 w-10 items-center justify-center rounded-full bg-background transition hover:bg-border"
        aria-label="Notifikasi"
      >
        <BellIcon />
        {unreadCount > 0 && (
          <span className="absolute right-1.5 top-1.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-danger px-1 text-[10px] font-bold text-white">
            {unreadCount > 9 ? '9+' : unreadCount}
          </span>
        )}
      </button>

      {isOpen && (
        <div className="absolute right-0 z-20 mt-2 w-80 rounded-card border border-border bg-surface shadow-card">
          <div className="flex items-center justify-between border-b border-border px-4 py-3">
            <p className="text-small font-semibold text-text-primary">Notifikasi</p>
            {unreadCount > 0 && (
              <button
                onClick={markAllRead}
                className="text-small font-medium text-primary hover:underline"
              >
                Tandai semua dibaca
              </button>
            )}
          </div>

          <div className="max-h-96 overflow-y-auto">
            {items.length === 0 ? (
              <p className="px-4 py-6 text-center text-small text-text-secondary">
                Belum ada notifikasi.
              </p>
            ) : (
              items.map((notification) => (
                <NotificationRow
                  key={notification.id}
                  notification={notification}
                  onRead={() => markRead(notification.id)}
                />
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
}

function NotificationRow({
  notification,
  onRead,
}: {
  notification: AppNotification;
  onRead: () => void;
}) {
  const content = (
    <div
      className={`flex flex-col gap-0.5 border-b border-border px-4 py-3 last:border-0 ${
        notification.isRead ? '' : 'bg-[rgba(0,82,156,0.06)]'
      }`}
    >
      <p className="text-small font-semibold text-text-primary">{notification.title}</p>
      <p className="text-small text-text-secondary">{notification.body}</p>
      <p className="text-[11px] text-text-secondary">
        {dateFormatter.format(new Date(notification.createdAt))}
      </p>
    </div>
  );

  if (notification.relatedTaskId) {
    return (
      <Link href={`/tasks/${notification.relatedTaskId}`} onClick={onRead} className="block hover:bg-background">
        {content}
      </Link>
    );
  }

  return (
    <button onClick={onRead} className="block w-full text-left hover:bg-background">
      {content}
    </button>
  );
}

function BellIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
      <path
        d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}
