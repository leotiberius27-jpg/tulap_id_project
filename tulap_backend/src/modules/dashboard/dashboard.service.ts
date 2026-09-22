import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import {
  DashboardPeriodEnum,
  DashboardQueryDto,
} from './dto/dashboard-query.dto';
import {
  ActionRequiredItemDto,
  ActivityTrendPointDto,
  DashboardResponseDto,
  DashboardSummaryDto,
  ExpenseCategoryItemDto,
  TopLocationItemDto,
  TravelDestinationItemDto,
} from './dto/dashboard-response.dto';

@Injectable()
export class DashboardService {
  private readonly logger = new Logger(DashboardService.name);

  constructor(private readonly prisma: PrismaService) {}

  async getDashboard(
    queryDto: DashboardQueryDto,
    user: AuthenticatedUser,
  ): Promise<DashboardResponseDto> {
    const isPrivileged =
      (user.role === 'ADMIN' || user.role === 'SUPER_ADMIN') &&
      queryDto.scope === 'team';

    // 1. Resolve date range
    const { dateFrom, dateTo, periodType, periodLabel } =
      this.resolveDateRange(queryDto);

    // 2. Fetch data in parallel with proper user scoping
    const taskWhere: any = {};
    if (!isPrivileged) {
      taskWhere.OR = [{ assigneeId: user.id }, { creatorId: user.id }];
    }
    taskWhere.startDate = { gte: dateFrom, lte: dateTo };

    const photoWhere: any = {};
    if (!isPrivileged) {
      photoWhere.uploaderId = user.id;
    }
    photoWhere.createdAt = { gte: dateFrom, lte: dateTo };

    const expenseWhere: any = {};
    if (!isPrivileged) {
      expenseWhere.ownerId = user.id;
    }
    expenseWhere.createdAt = { gte: dateFrom, lte: dateTo };

    const travelWhere: any = {};
    if (!isPrivileged) {
      travelWhere.userId = user.id;
    }
    travelWhere.departureDate = { gte: dateFrom, lte: dateTo };

    const [tasks, photos, expenses, travelMissions] = await Promise.all([
      this.prisma.task_SPPD.findMany({
        where: taskWhere,
        orderBy: { startDate: 'desc' },
      }),
      this.prisma.geotag_Photo.findMany({
        where: photoWhere,
        select: {
          id: true,
          createdAt: true,
          latitude: true,
          longitude: true,
          address: true,
          photoUrl: true,
        },
      }),
      this.prisma.expense_Note.findMany({
        where: expenseWhere,
        select: {
          id: true,
          totalAmount: true,
          category: true,
          verificationStatus: true,
          createdAt: true,
        },
      }),
      this.prisma.travel_Mission.findMany({
        where: travelWhere,
        include: {
          lpjPackages: true,
        },
      }),
    ]);

    // 3. Compute Activity Summary
    const activityTotal = tasks.length;
    const activityCompleted = tasks.filter(
      (t) => t.status === 'COMPLETED' || t.status === 'VERIFIED',
    ).length;
    const activityOngoing = tasks.filter(
      (t) =>
        t.status === 'ONGOING' ||
        t.status === 'PENDING_VERIFICATION' ||
        t.status === 'REVISION_NEEDED' ||
        t.status === 'DRAFT',
    ).length;
    const activityCompletionRate =
      activityTotal > 0
        ? Number(((activityCompleted / activityTotal) * 100).toFixed(1))
        : 0;

    // 4. Compute Evidence Summary
    const photoCount = photos.length;
    const videoCount = 0; // Geotag_Photo stores photos, video support in evidence schema
    const evidenceTotal = photos.length;

    // 5. Compute Travel & LPJ Summary
    const travelTotal = travelMissions.length;
    const travelCompleted = travelMissions.filter(
      (tm) => tm.status === 'COMPLETED',
    ).length;
    let travelDays = 0;
    let lpjComplete = 0;
    let lpjIncomplete = 0;
    const destinationsMap = new Map<string, number>();

    for (const tm of travelMissions) {
      if (tm.departureDate && tm.returnDate) {
        const diffMs =
          new Date(tm.returnDate).getTime() -
          new Date(tm.departureDate).getTime();
        const days = Math.max(1, Math.ceil(diffMs / (1000 * 60 * 60 * 24)));
        travelDays += days;
      }

      if (tm.lpjPackages && tm.lpjPackages.length > 0 && tm.status === 'COMPLETED') {
        lpjComplete++;
      } else {
        lpjIncomplete++;
      }

      const dest = tm.destination || 'Lainnya';
      destinationsMap.set(dest, (destinationsMap.get(dest) || 0) + 1);
    }

    const travelDestinations: TravelDestinationItemDto[] = Array.from(
      destinationsMap.entries(),
    )
      .map(([destination, count]) => ({ destination, count }))
      .sort((a, b) => b.count - a.count);

    // 6. Compute Expense Intelligence (Strict Confirmed vs Pending Review)
    let expenseTotal = 0;
    const expenseCategoryMap = new Map<
      string,
      { amount: number; count: number }
    >();
    let unconfirmedExpenseCount = 0;

    for (const exp of expenses) {
      const isConfirmed = exp.verificationStatus === 'VERIFIED';

      if (isConfirmed) {
        const amount = Number(exp.totalAmount || 0);
        expenseTotal += amount;
        const cat = this.normalizeCategory(String(exp.category || 'LAINNYA'));
        const prev = expenseCategoryMap.get(cat) || { amount: 0, count: 0 };
        expenseCategoryMap.set(cat, {
          amount: prev.amount + amount,
          count: prev.count + 1,
        });
      } else {
        unconfirmedExpenseCount++;
      }
    }

    const expenseByCategory: ExpenseCategoryItemDto[] = Array.from(
      expenseCategoryMap.entries(),
    )
      .map(([category, data]) => ({
        category,
        amount: data.amount,
        count: data.count,
        percentage:
          expenseTotal > 0
            ? Number(((data.amount / expenseTotal) * 100).toFixed(1))
            : 0,
      }))
      .sort((a, b) => b.amount - a.amount);

    // 7. Compute Action Required Items
    const actionRequired: ActionRequiredItemDto[] = [];

    if (lpjIncomplete > 0) {
      actionRequired.push({
        type: 'lpjIncomplete',
        title: `${lpjIncomplete} LPJ belum lengkap`,
        subtitle: 'Lengkapi dokumen bukti & tanda tangan perjalanan dinas',
        count: lpjIncomplete,
        severity: 'warning',
        filterParams: { entityType: 'LPJ', status: 'INCOMPLETE' },
      });
    }

    if (unconfirmedExpenseCount > 0) {
      actionRequired.push({
        type: 'receiptNeedsReview',
        title: `${unconfirmedExpenseCount} nota perlu ditinjau`,
        subtitle: 'Periksa hasil pindaian OCR & konfirmasi nominal',
        count: unconfirmedExpenseCount,
        severity: 'info',
        filterParams: { entityType: 'RECEIPT', status: 'DRAFT' },
      });
    }

    const revisionNeededTasks = tasks.filter(
      (t) => t.status === 'REVISION_NEEDED',
    );
    if (revisionNeededTasks.length > 0) {
      actionRequired.push({
        type: 'activityIncomplete',
        title: `${revisionNeededTasks.length} kegiatan perlu perbaikan`,
        subtitle: 'Cek catatan verifikator dan perbarui dokumentasi',
        count: revisionNeededTasks.length,
        severity: 'danger',
        filterParams: { entityType: 'ACTIVITY', status: 'REVISION_NEEDED' },
      });
    }

    // 8. Compute Activity Trend (Daily or Monthly Buckets)
    const activityTrend = this.computeActivityTrend(tasks, dateFrom, dateTo);

    // 9. Compute Top Locations
    const locationMap = new Map<
      string,
      { count: number; latSum: number; lngSum: number }
    >();

    for (const t of tasks) {
      const loc = this.extractCityOrLocation(t.destination || 'Wilayah Tugas');
      const prev = locationMap.get(loc) || { count: 0, latSum: 0, lngSum: 0 };
      locationMap.set(loc, {
        count: prev.count + 1,
        latSum: prev.latSum,
        lngSum: prev.lngSum,
      });
    }

    for (const p of photos) {
      if (p.address) {
        const loc = this.extractCityOrLocation(p.address);
        const prev = locationMap.get(loc) || { count: 0, latSum: 0, lngSum: 0 };
        const lat = p.latitude != null ? Number(p.latitude) : 0;
        const lng = p.longitude != null ? Number(p.longitude) : 0;
        locationMap.set(loc, {
          count: prev.count + 1,
          latSum: prev.latSum + lat,
          lngSum: prev.lngSum + lng,
        });
      }
    }

    // Kegiatan per klaster lokasi (diurutkan terbaru dulu) - dipakai untuk
    // kartu "kegiatan terbaru" di Beranda & linimasa di halaman detail
    // lokasi, BUKAN untuk hitung `count` di atas (count tetap gabungan
    // task+foto seperti semula supaya tidak mengubah statistik existing).
    const locationTasksMap = new Map<string, typeof tasks>();
    for (const t of tasks) {
      const loc = this.extractCityOrLocation(t.destination || 'Wilayah Tugas');
      const arr = locationTasksMap.get(loc) || [];
      arr.push(t);
      locationTasksMap.set(loc, arr);
    }
    for (const arr of locationTasksMap.values()) {
      arr.sort((a, b) => b.startDate.getTime() - a.startDate.getTime());
    }

    // Foto geotag terbaru per klaster lokasi - dipakai sebagai thumbnail
    // kartu (mendekati foto "sampul" kegiatan di lokasi itu).
    const locationPhotoMap = new Map<string, { url: string; createdAt: Date }>();
    for (const p of photos) {
      if (!p.address) continue;
      const loc = this.extractCityOrLocation(p.address);
      const prev = locationPhotoMap.get(loc);
      if (!prev || p.createdAt > prev.createdAt) {
        locationPhotoMap.set(loc, { url: p.photoUrl, createdAt: p.createdAt });
      }
    }

    const topLocations: TopLocationItemDto[] = Array.from(locationMap.entries())
      .map(([location, data]) => {
        const locTasks = locationTasksMap.get(location) || [];
        const activities = locTasks.slice(0, 20).map((t) => ({
          taskId: t.id,
          title: t.taskName,
          status: t.status,
          date: t.startDate.toISOString(),
        }));
        return {
          location,
          count: data.count,
          latitude: data.count > 0 && data.latSum !== 0 ? data.latSum / data.count : undefined,
          longitude: data.count > 0 && data.lngSum !== 0 ? data.lngSum / data.count : undefined,
          thumbnailUrl: locationPhotoMap.get(location)?.url,
          latestActivity: activities[0],
          activities,
        };
      })
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);

    // 10. Generate Deterministic Traceable Insights
    const insights = this.generateDeterministicInsights({
      activityTotal,
      activityCompleted,
      expenseTotal,
      topCategory: expenseByCategory[0]?.category,
      topLocation: topLocations[0]?.location,
      lpjIncomplete,
    });

    const summary: DashboardSummaryDto = {
      activityTotal,
      activityCompleted,
      activityOngoing,
      activityCompletionRate,
      photoCount,
      videoCount,
      evidenceTotal,
      travelTotal,
      travelCompleted,
      travelDays,
      expenseTotal,
      reportCount: activityCompleted,
      lpjComplete,
      lpjIncomplete,
    };

    return {
      period: {
        type: periodType,
        dateFrom: dateFrom.toISOString(),
        dateTo: dateTo.toISOString(),
        label: periodLabel,
      },
      summary,
      actionRequired,
      activityTrend,
      expenseByCategory,
      topLocations,
      travelDestinations,
      insights,
    };
  }

  private resolveDateRange(query: DashboardQueryDto): {
    dateFrom: Date;
    dateTo: Date;
    periodType: string;
    periodLabel: string;
  } {
    const now = new Date();
    const period = query.period || DashboardPeriodEnum.THIS_MONTH;

    if (query.year) {
      const start = new Date(Date.UTC(query.year, 0, 1, 0, 0, 0));
      const end = new Date(Date.UTC(query.year, 11, 31, 23, 59, 59));
      return {
        dateFrom: start,
        dateTo: end,
        periodType: 'year',
        periodLabel: `Tahun ${query.year}`,
      };
    }

    if (query.dateFrom && query.dateTo) {
      return {
        dateFrom: new Date(query.dateFrom),
        dateTo: new Date(query.dateTo),
        periodType: 'custom',
        periodLabel: 'Kustom',
      };
    }

    switch (period) {
      case DashboardPeriodEnum.TODAY: {
        const start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
        const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
        return { dateFrom: start, dateTo: end, periodType: 'today', periodLabel: 'Hari Ini' };
      }
      case DashboardPeriodEnum.SEVEN_DAYS: {
        const start = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        return { dateFrom: start, dateTo: now, periodType: 'sevenDays', periodLabel: '7 Hari Terakhir' };
      }
      case DashboardPeriodEnum.THIRTY_DAYS: {
        const start = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        return { dateFrom: start, dateTo: now, periodType: 'thirtyDays', periodLabel: '30 Hari Terakhir' };
      }
      case DashboardPeriodEnum.THIS_YEAR: {
        const start = new Date(now.getFullYear(), 0, 1, 0, 0, 0);
        const end = new Date(now.getFullYear(), 11, 31, 23, 59, 59);
        return { dateFrom: start, dateTo: end, periodType: 'thisYear', periodLabel: `Tahun ${now.getFullYear()}` };
      }
      case DashboardPeriodEnum.THIS_MONTH:
      default: {
        const start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);
        const end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
        const monthNames = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
        ];
        return {
          dateFrom: start,
          dateTo: end,
          periodType: 'thisMonth',
          periodLabel: `${monthNames[now.getMonth()]} ${now.getFullYear()}`,
        };
      }
    }
  }

  private computeActivityTrend(
    tasks: any[],
    dateFrom: Date,
    dateTo: Date,
  ): ActivityTrendPointDto[] {
    const diffDays = Math.ceil(
      (dateTo.getTime() - dateFrom.getTime()) / (1000 * 60 * 60 * 24),
    );

    // If span > 60 days, group by month
    if (diffDays > 60) {
      const monthBuckets = new Map<string, number>();
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

      for (const t of tasks) {
        const d = new Date(t.startDate);
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
        monthBuckets.set(key, (monthBuckets.get(key) || 0) + 1);
      }

      return Array.from(monthBuckets.entries())
        .sort((a, b) => a[0].localeCompare(b[0]))
        .map(([key, count]) => {
          const monthIdx = parseInt(key.split('-')[1], 10) - 1;
          return {
            date: `${key}-01`,
            label: monthNames[monthIdx] || key,
            count,
          };
        });
    }

    // Otherwise group by day
    const dayBuckets = new Map<string, number>();
    for (const t of tasks) {
      const d = new Date(t.startDate);
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      dayBuckets.set(key, (dayBuckets.get(key) || 0) + 1);
    }

    const points: ActivityTrendPointDto[] = [];
    const curr = new Date(dateFrom);
    const monthNamesShort = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    while (curr <= dateTo) {
      const key = `${curr.getFullYear()}-${String(curr.getMonth() + 1).padStart(2, '0')}-${String(curr.getDate()).padStart(2, '0')}`;
      const label = `${curr.getDate()} ${monthNamesShort[curr.getMonth()]}`;
      points.push({
        date: key,
        label,
        count: dayBuckets.get(key) || 0,
      });
      curr.setDate(curr.getDate() + 1);
    }

    return points;
  }

  private normalizeCategory(cat: string): string {
    const c = cat.toLowerCase();
    if (c.includes('transport') || c.includes('tiket') || c.includes('taxi')) return 'Transportasi';
    if (c.includes('hotel') || c.includes('inap') || c.includes('penginapan')) return 'Penginapan';
    if (c.includes('bbm') || c.includes('bensin') || c.includes('solar') || c.includes('bahan bakar')) return 'BBM';
    if (c.includes('makan') || c.includes('konsumsi') || c.includes('resto') || c.includes('kuliner')) return 'Konsumsi';
    return 'Lainnya';
  }

  private extractCityOrLocation(addr: string): string {
    if (!addr) return 'Wilayah Tugas';
    const parts = addr.split(',').map((p) => p.trim());
    for (const part of parts) {
      if (
        part.toLowerCase().includes('mimika') ||
        part.toLowerCase().includes('timika') ||
        part.toLowerCase().includes('jayapura') ||
        part.toLowerCase().includes('nabire') ||
        part.toLowerCase().includes('merauke') ||
        part.toLowerCase().includes('jakarta') ||
        part.toLowerCase().includes('surabaya')
      ) {
        return part;
      }
    }
    return parts[parts.length - 1] || parts[0] || 'Wilayah Tugas';
  }

  private generateDeterministicInsights(data: {
    activityTotal: number;
    activityCompleted: number;
    expenseTotal: number;
    topCategory?: string;
    topLocation?: string;
    lpjIncomplete: number;
  }): string[] {
    const list: string[] = [];

    if (data.activityTotal > 0) {
      list.push(
        `${data.activityCompleted} dari ${data.activityTotal} kegiatan lapangan telah selesai.`,
      );
    }
    if (data.topLocation) {
      list.push(`Pusat kegiatan utama pada periode ini berada di ${data.topLocation}.`);
    }
    if (data.expenseTotal > 0 && data.topCategory) {
      list.push(`Alokasi pengeluaran terbesar dicatat pada kategori ${data.topCategory}.`);
    }
    if (data.lpjIncomplete > 0) {
      list.push(`Terdapat ${data.lpjIncomplete} berkas LPJ perjalanan yang masih perlu dilengkapi.`);
    }

    return list;
  }
}
