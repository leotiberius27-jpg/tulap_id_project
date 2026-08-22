'use client';

import Link from 'next/link';
import { Task } from '@/lib/types';
import { StatusBadge } from './status-badge';
import { MapPin, Calendar, Receipt, Camera, CheckSquare, ArrowRight } from 'lucide-react';

const rupiah = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  minimumFractionDigits: 0,
});

export function TaskCard({ task, index }: { task: Task; index: number }) {
  // Generate concise short code e.g. "T1", "T2" or extract number
  const shortCode = `T${index + 1}`;

  // Format date and time
  const startDate = new Date(task.startDate);
  const formattedDate = new Intl.DateTimeFormat('id-ID', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  }).format(startDate);

  const formattedTime = new Intl.DateTimeFormat('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
  }).format(startDate);

  return (
    <div className="bg-surface rounded-card p-5 border border-border/80 shadow-card hover:shadow-dropdown transition-all flex flex-col justify-between group">
      <div>
        {/* Card Header matching reference */}
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="flex items-center gap-3">
            {/* Square Code Badge */}
            <div className="w-10 h-10 rounded-xl bg-primary/10 text-primary font-bold text-sm flex items-center justify-center shrink-0 border border-primary/20">
              {shortCode}
            </div>
            <div>
              <h3 className="text-body font-bold text-text-primary group-hover:text-primary transition line-clamp-1">
                {task.assignee.fullName}
              </h3>
              <p className="text-[12px] text-text-secondary line-clamp-1">
                {task.taskCode} · {task.destination}
              </p>
            </div>
          </div>
          <StatusBadge status={task.status} />
        </div>

        {/* Date & Time Row */}
        <div className="flex items-center justify-between text-[12px] text-text-secondary/90 py-2 border-b border-border/60 mb-3">
          <div className="flex items-center gap-1.5">
            <Calendar className="w-3.5 h-3.5 text-text-secondary" />
            <span>{formattedDate}</span>
          </div>
          <span className="font-medium text-text-primary/80">{formattedTime} WIB</span>
        </div>

        {/* Itemized Table Breakdown */}
        <div className="space-y-2 text-small mb-4">
          <div className="flex items-center justify-between text-[11px] font-semibold text-text-secondary/70 uppercase tracking-wider">
            <span>Uraian / Bukti</span>
            <span className="text-center w-12">Qty</span>
            <span className="text-right">Estimasi</span>
          </div>

          <div className="flex items-center justify-between text-text-primary py-1 border-b border-border/40 text-xs">
            <span className="truncate pr-2 flex items-center gap-1.5">
              <Camera className="w-3.5 h-3.5 text-primary shrink-0" />
              <span>Foto Geotag Lapangan</span>
            </span>
            <span className="text-center w-12 text-text-secondary">1 titik</span>
            <span className="text-right font-medium text-text-primary">Valid</span>
          </div>

          <div className="flex items-center justify-between text-text-primary py-1 border-b border-border/40 text-xs">
            <span className="truncate pr-2 flex items-center gap-1.5">
              <Receipt className="w-3.5 h-3.5 text-amber-600 shrink-0" />
              <span>Klaim Nota &amp; BBM</span>
            </span>
            <span className="text-center w-12 text-text-secondary">Terlampir</span>
            <span className="text-right font-medium text-text-primary">
              {rupiah.format(Number(task.realizedAmount || task.budgetAmount))}
            </span>
          </div>

          <div className="flex items-center justify-between text-text-primary py-1 text-xs">
            <span className="truncate pr-2 flex items-center gap-1.5">
              <CheckSquare className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
              <span>Checklist &amp; Lokasi</span>
            </span>
            <span className="text-center w-12 text-text-secondary">Lengkap</span>
            <span className="text-right font-medium text-emerald-600">Siap Review</span>
          </div>
        </div>
      </div>

      {/* Card Footer matching reference with Total & Actions */}
      <div className="pt-3 border-t border-border flex items-center justify-between mt-auto">
        <div>
          <p className="text-[11px] font-medium text-text-secondary uppercase tracking-wider">Total Anggaran</p>
          <p className="text-body font-bold text-text-primary">
            {rupiah.format(Number(task.budgetAmount))}
          </p>
        </div>

        <div className="flex items-center gap-2">
          <Link
            href={`/tasks/${task.id}`}
            className="px-3 py-1.5 text-xs font-semibold text-text-secondary hover:text-text-primary hover:bg-background rounded-button transition"
          >
            Lihat Detail
          </Link>
          <Link
            href={`/tasks/${task.id}`}
            className="px-3.5 py-1.5 text-xs font-semibold text-white bg-primary hover:bg-primary-hover rounded-button shadow-sm transition flex items-center gap-1"
          >
            <span>Verifikasi</span>
            <ArrowRight className="w-3 h-3" />
          </Link>
        </div>
      </div>
    </div>
  );
}
