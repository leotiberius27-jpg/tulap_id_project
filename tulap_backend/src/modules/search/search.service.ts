import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import {
  SearchQueryDto,
  SearchEntityTypeEnum,
  SearchSortEnum,
} from './dto/search-query.dto';
import {
  SearchResultItemDto,
  SearchResponseDto,
} from './dto/search-result.dto';

@Injectable()
export class SearchService {
  private readonly logger = new Logger(SearchService.name);

  constructor(private readonly prisma: PrismaService) {}

  async search(
    queryDto: SearchQueryDto,
    user: AuthenticatedUser,
  ): Promise<SearchResponseDto> {
    const rawQuery = queryDto.q?.trim() || '';
    const normalizedQuery = rawQuery.toLowerCase();
    const cleanAmount = this.extractNumericAmount(rawQuery);
    const limit = queryDto.limit || 20;

    const requestedTypes =
      queryDto.entityTypes && queryDto.entityTypes.length > 0
        ? queryDto.entityTypes
        : Object.values(SearchEntityTypeEnum);

    const isPrivileged =
      user.role === 'ADMIN' ||
      user.role === 'SUPER_ADMIN' ||
      user.role === 'VERIFIKATOR';

    const results: SearchResultItemDto[] = [];

    // Helper date filters
    let dateFrom: Date | undefined;
    let dateTo: Date | undefined;

    if (queryDto.year) {
      dateFrom = new Date(Date.UTC(queryDto.year, 0, 1, 0, 0, 0));
      dateTo = new Date(Date.UTC(queryDto.year, 11, 31, 23, 59, 59));
    } else {
      if (queryDto.dateFrom) dateFrom = new Date(queryDto.dateFrom);
      if (queryDto.dateTo) dateTo = new Date(queryDto.dateTo);
    }

    // 1. Search Activities (Task_SPPD)
    if (requestedTypes.includes(SearchEntityTypeEnum.ACTIVITY)) {
      const taskWhere: any = {};
      if (!isPrivileged) {
        taskWhere.OR = [{ assigneeId: user.id }, { creatorId: user.id }];
      }
      if (dateFrom || dateTo) {
        taskWhere.startDate = {};
        if (dateFrom) taskWhere.startDate.gte = dateFrom;
        if (dateTo) taskWhere.startDate.lte = dateTo;
      }
      if (queryDto.status) {
        taskWhere.status = queryDto.status;
      }

      const tasks = await this.prisma.task_SPPD.findMany({
        where: taskWhere,
        include: {
          geotagPhotos: { select: { id: true } },
          expenseNotes: { select: { id: true } },
          travelMission: { select: { id: true, title: true, displayId: true } },
        },
        take: 100,
      });

      for (const t of tasks) {
        const score = this.calculateActivityRelevance(t, normalizedQuery, cleanAmount);
        if (rawQuery.length === 0 || score > 0) {
          results.push({
            entityId: t.id,
            entityType: SearchEntityTypeEnum.ACTIVITY,
            title: t.taskName,
            subtitle: `${t.taskCode} • ${t.destination}`,
            date: t.startDate.toISOString(),
            location: t.destination,
            relevanceScore: score,
            syncStatus: 'SYNCED',
            parentId: t.travelMissionId,
            matchedField: this.getMatchedField(t, normalizedQuery),
            metadata: {
              taskCode: t.taskCode,
              status: t.status,
              photoCount: t.geotagPhotos.length,
              expenseCount: t.expenseNotes.length,
              budgetAmount: t.budgetAmount.toString(),
            },
          });
        }
      }
    }

    // 2. Search Travel Missions
    if (requestedTypes.includes(SearchEntityTypeEnum.TRAVEL)) {
      const travelWhere: any = {};
      if (!isPrivileged) {
        travelWhere.userId = user.id;
      }
      if (dateFrom || dateTo) {
        travelWhere.departureDate = {};
        if (dateFrom) travelWhere.departureDate.gte = dateFrom;
        if (dateTo) travelWhere.departureDate.lte = dateTo;
      }
      if (queryDto.status) {
        travelWhere.status = queryDto.status;
      }

      const missions = await this.prisma.travel_Mission.findMany({
        where: travelWhere,
        include: {
          tasks: { select: { id: true } },
          supportingDocuments: { select: { id: true } },
          lpjPackages: { select: { id: true } },
        },
        take: 100,
      });

      for (const m of missions) {
        const score = this.calculateTravelRelevance(m, normalizedQuery, cleanAmount);
        if (rawQuery.length === 0 || score > 0) {
          results.push({
            entityId: m.id,
            entityType: SearchEntityTypeEnum.TRAVEL,
            title: m.title,
            subtitle: `${m.displayId} • ${m.origin} → ${m.destination}`,
            date: m.departureDate.toISOString(),
            location: m.destination,
            relevanceScore: score,
            syncStatus: 'SYNCED',
            metadata: {
              displayId: m.displayId,
              assignmentLetterNumber: m.assignmentLetterNumber,
              status: m.status,
              transportMode: m.transportMode,
              taskCount: m.tasks.length,
              documentCount: m.supportingDocuments.length,
              lpjCount: m.lpjPackages.length,
            },
          });
        }
      }
    }

    // 3. Search Evidence (Geotag Photos)
    if (requestedTypes.includes(SearchEntityTypeEnum.EVIDENCE)) {
      const photoWhere: any = {};
      if (!isPrivileged) {
        photoWhere.uploaderId = user.id;
      }
      if (dateFrom || dateTo) {
        photoWhere.serverTimestamp = {};
        if (dateFrom) photoWhere.serverTimestamp.gte = dateFrom;
        if (dateTo) photoWhere.serverTimestamp.lte = dateTo;
      }

      const photos = await this.prisma.geotag_Photo.findMany({
        where: photoWhere,
        include: {
          task: { select: { id: true, taskName: true, taskCode: true } },
        },
        take: 100,
      });

      for (const p of photos) {
        const score = this.calculateEvidenceRelevance(p, normalizedQuery);
        if (rawQuery.length === 0 || score > 0) {
          results.push({
            entityId: p.id,
            entityType: SearchEntityTypeEnum.EVIDENCE,
            title: p.caption || p.task.taskName,
            subtitle: p.address || `${p.latitude}, ${p.longitude}`,
            date: p.serverTimestamp.toISOString(),
            location: p.address,
            thumbnailUrl: p.photoUrl,
            relevanceScore: score,
            syncStatus: 'SYNCED',
            parentId: p.taskId,
            metadata: {
              latitude: p.latitude.toString(),
              longitude: p.longitude.toString(),
              integrityHash: p.integrityHash,
              taskName: p.task.taskName,
            },
          });
        }
      }
    }

    // 4. Search Receipts & Expenses
    if (
      requestedTypes.includes(SearchEntityTypeEnum.RECEIPT) ||
      requestedTypes.includes(SearchEntityTypeEnum.EXPENSE)
    ) {
      const expenseWhere: any = {};
      if (!isPrivileged) {
        expenseWhere.ownerId = user.id;
      }
      if (dateFrom || dateTo) {
        expenseWhere.transactionDate = {};
        if (dateFrom) expenseWhere.transactionDate.gte = dateFrom;
        if (dateTo) expenseWhere.transactionDate.lte = dateTo;
      }
      if (queryDto.category) {
        expenseWhere.category = queryDto.category.toUpperCase();
      }

      const expenses = await this.prisma.expense_Note.findMany({
        where: expenseWhere,
        include: {
          task: { select: { id: true, taskName: true, taskCode: true } },
        },
        take: 100,
      });

      for (const e of expenses) {
        const score = this.calculateExpenseRelevance(e, normalizedQuery, cleanAmount);
        if (rawQuery.length === 0 || score > 0) {
          results.push({
            entityId: e.id,
            entityType: SearchEntityTypeEnum.RECEIPT,
            title: e.vendorName,
            subtitle: `${e.category} • Rp ${Number(e.totalAmount).toLocaleString('id-ID')}`,
            date: e.transactionDate.toISOString(),
            thumbnailUrl: e.scanUrl,
            relevanceScore: score,
            syncStatus: 'SYNCED',
            parentId: e.taskId,
            metadata: {
              category: e.category,
              totalAmount: e.totalAmount.toString(),
              vendorName: e.vendorName,
              verificationStatus: e.verificationStatus,
              ocrConfidence: e.ocrConfidence?.toString(),
              taskName: e.task.taskName,
            },
          });
        }
      }
    }

    // 5. Search Supporting Documents
    if (requestedTypes.includes(SearchEntityTypeEnum.DOCUMENT)) {
      const docWhere: any = {};
      if (!isPrivileged) {
        docWhere.travelMission = { userId: user.id };
      }

      const docs = await this.prisma.supporting_Document.findMany({
        where: docWhere,
        include: {
          travelMission: { select: { id: true, title: true, displayId: true } },
        },
        take: 100,
      });

      for (const d of docs) {
        const score = this.calculateDocumentRelevance(d, normalizedQuery);
        if (rawQuery.length === 0 || score > 0) {
          results.push({
            entityId: d.id,
            entityType: SearchEntityTypeEnum.DOCUMENT,
            title: d.title,
            subtitle: `${d.documentType} • ${d.travelMission.title}`,
            date: d.createdAt.toISOString(),
            thumbnailUrl: d.documentUrl,
            relevanceScore: score,
            syncStatus: 'SYNCED',
            parentId: d.travelMissionId,
            metadata: {
              documentType: d.documentType,
              travelDisplayId: d.travelMission.displayId,
              sha256: d.sha256,
            },
          });
        }
      }
    }

    // 6. Search LPJ Packages
    if (requestedTypes.includes(SearchEntityTypeEnum.LPJ)) {
      const lpjWhere: any = {};
      if (!isPrivileged) {
        lpjWhere.travelMission = { userId: user.id };
      }

      const lpjs = await this.prisma.lPJ_Package.findMany({
        where: lpjWhere,
        include: {
          travelMission: { select: { id: true, title: true, displayId: true } },
        },
        take: 100,
      });

      for (const l of lpjs) {
        const score = this.calculateLpjRelevance(l, normalizedQuery);
        if (rawQuery.length === 0 || score > 0) {
          results.push({
            entityId: l.id,
            entityType: SearchEntityTypeEnum.LPJ,
            title: l.title,
            subtitle: `${l.packageCode} (v${l.versionNumber}) • ${l.travelMission.title}`,
            date: l.createdAt.toISOString(),
            relevanceScore: score,
            syncStatus: 'SYNCED',
            parentId: l.travelMissionId,
            metadata: {
              packageCode: l.packageCode,
              versionNumber: l.versionNumber,
              completenessScore: l.completenessScore.toString(),
              totalActualExpense: l.totalActualExpense.toString(),
              pdfUrl: l.pdfUrl,
              packageSha256: l.packageSha256,
            },
          });
        }
      }
    }

    // Sort results
    if (queryDto.sort === SearchSortEnum.NEWEST) {
      results.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
    } else if (queryDto.sort === SearchSortEnum.OLDEST) {
      results.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    } else {
      // Relevance first, then newest
      results.sort((a, b) => {
        if (b.relevanceScore !== a.relevanceScore) {
          return b.relevanceScore - a.relevanceScore;
        }
        return new Date(b.date).getTime() - new Date(a.date).getTime();
      });
    }

    // Cursor pagination
    let startIndex = 0;
    if (queryDto.cursor) {
      const cursorIndex = results.findIndex((r) => r.entityId === queryDto.cursor);
      if (cursorIndex !== -1) {
        startIndex = cursorIndex + 1;
      }
    }

    const pagedItems = results.slice(startIndex, startIndex + limit);
    const hasMore = startIndex + limit < results.length;
    const nextCursor = hasMore && pagedItems.length > 0
      ? pagedItems[pagedItems.length - 1].entityId
      : null;

    return {
      items: pagedItems,
      totalCount: results.length,
      nextCursor,
      hasMore,
      query: rawQuery,
    };
  }

  private extractNumericAmount(text: string): number | null {
    const clean = text.replace(/[^0-9]/g, '');
    if (!clean || clean.length < 3) return null;
    const num = parseFloat(clean);
    return isNaN(num) ? null : num;
  }

  private calculateActivityRelevance(
    t: any,
    query: string,
    cleanAmount: number | null,
  ): number {
    if (!query) return 10;
    const code = t.taskCode.toLowerCase();
    const name = t.taskName.toLowerCase();
    const dest = t.destination.toLowerCase();
    const desc = (t.description || '').toLowerCase();

    if (code === query) return 100;
    if (code.includes(query)) return 85;
    if (name === query) return 90;
    if (name.includes(query)) return 70;
    if (dest.includes(query)) return 50;
    if (desc.includes(query)) return 30;

    if (cleanAmount !== null && Math.abs(Number(t.budgetAmount) - cleanAmount) < 1) {
      return 60;
    }

    return 0;
  }

  private calculateTravelRelevance(
    m: any,
    query: string,
    cleanAmount: number | null,
  ): number {
    if (!query) return 10;
    const displayId = m.displayId.toLowerCase();
    const letter = m.assignmentLetterNumber.toLowerCase();
    const title = m.title.toLowerCase();
    const origin = m.origin.toLowerCase();
    const dest = m.destination.toLowerCase();
    const purpose = m.purpose.toLowerCase();

    if (displayId === query) return 100;
    if (displayId.includes(query)) return 85;
    if (letter === query || letter.includes(query)) return 80;
    if (title === query) return 90;
    if (title.includes(query)) return 70;
    if (dest.includes(query) || origin.includes(query)) return 50;
    if (purpose.includes(query)) return 40;

    return 0;
  }

  private calculateEvidenceRelevance(p: any, query: string): number {
    if (!query) return 10;
    const id = p.id.toLowerCase();
    const caption = (p.caption || '').toLowerCase();
    const address = (p.address || '').toLowerCase();
    const taskName = (p.task?.taskName || '').toLowerCase();

    if (id === query) return 100;
    if (id.includes(query)) return 80;
    if (caption.includes(query)) return 70;
    if (address.includes(query)) return 50;
    if (taskName.includes(query)) return 40;

    return 0;
  }

  private calculateExpenseRelevance(
    e: any,
    query: string,
    cleanAmount: number | null,
  ): number {
    if (!query) return 10;
    const vendor = e.vendorName.toLowerCase();
    const category = e.category.toLowerCase();
    const ocr = (e.ocrRawText || '').toLowerCase();

    if (vendor === query) return 90;
    if (vendor.includes(query)) return 75;
    if (category.includes(query)) return 50;

    if (cleanAmount !== null && Math.abs(Number(e.totalAmount) - cleanAmount) < 1) {
      return 85;
    }

    // Secondary match: Raw OCR
    if (ocr.includes(query)) return 25;

    return 0;
  }

  private calculateDocumentRelevance(d: any, query: string): number {
    if (!query) return 10;
    const id = d.id.toLowerCase();
    const title = d.title.toLowerCase();
    const type = d.documentType.toLowerCase();
    const travelTitle = (d.travelMission?.title || '').toLowerCase();

    if (id === query) return 100;
    if (title === query) return 90;
    if (title.includes(query)) return 70;
    if (type.includes(query)) return 40;
    if (travelTitle.includes(query)) return 35;

    return 0;
  }

  private calculateLpjRelevance(l: any, query: string): number {
    if (!query) return 10;
    const code = l.packageCode.toLowerCase();
    const title = l.title.toLowerCase();
    const travelTitle = (l.travelMission?.title || '').toLowerCase();

    if (code === query) return 100;
    if (code.includes(query)) return 85;
    if (title.includes(query)) return 70;
    if (travelTitle.includes(query)) return 40;

    return 0;
  }

  private getMatchedField(t: any, query: string): string | null {
    if (!query) return null;
    if (t.taskCode.toLowerCase().includes(query)) return 'Nomor Tugas';
    if (t.taskName.toLowerCase().includes(query)) return 'Judul Kegiatan';
    if (t.destination.toLowerCase().includes(query)) return 'Lokasi';
    return null;
  }
}
