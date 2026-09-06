import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../infrastructure/prisma/prisma.service';
import { AuthenticatedUser } from '../auth/interfaces/authenticated-user.interface';
import { SearchService } from '../search/search.service';
import { SearchEntityTypeEnum } from '../search/dto/search-query.dto';
import {
  AssistantQueryDto,
  AssistantContextEntityType,
} from './dto/assistant-query.dto';
import {
  AssistantActionDto,
  AssistantCardDto,
  AssistantIntentEnum,
  AssistantResponseDto,
  AssistantSourceDto,
} from './dto/assistant-response.dto';
import { AssistantLanguageModel } from './services/assistant-language-model.interface';

const rupiahFormatter = new Intl.NumberFormat('id-ID', {
  style: 'currency',
  currency: 'IDR',
  minimumFractionDigits: 0,
});

@Injectable()
export class AssistantService {
  private readonly logger = new Logger(AssistantService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly searchService: SearchService,
    private readonly languageModel: AssistantLanguageModel,
  ) {}

  async processQuery(
    dto: AssistantQueryDto,
    user: AuthenticatedUser,
  ): Promise<AssistantResponseDto> {
    const rawQuery = dto.query?.trim() || '';
    const qLower = rawQuery.toLowerCase();
    const isPrivileged =
      user.role === 'ADMIN' ||
      user.role === 'SUPER_ADMIN' ||
      user.role === 'VERIFIKATOR';

    // 1. Destructive action detection (Delete confirmation)
    if (
      qLower.includes('hapus foto') ||
      qLower.includes('hapus kegiatan') ||
      qLower.includes('hapus nota') ||
      qLower.includes('hapus bukti') ||
      qLower.includes('hapus semua')
    ) {
      return this.handleDestructiveAction(rawQuery, dto);
    }

    // 2. Write action detection (Mark complete, etc.)
    if (
      qLower.includes('selesaikan kegiatan') ||
      qLower.includes('tandai selesai') ||
      qLower.includes('tutup tugas')
    ) {
      return this.handleWriteAction(rawQuery, dto, user);
    }

    // 3. Exact ID Resolution (ACT-*, PD-*, LPJ-*)
    const exactIdMatch = rawQuery.match(/(ACT|PD|LPJ|REC|EVD)-\d{6,8}-[A-Za-z0-9]+/i);
    if (exactIdMatch) {
      const resolved = await this.resolveExactId(exactIdMatch[0], user, isPrivileged);
      if (resolved) return resolved;
    }

    // 4. Financial & Expense Totals
    if (
      qLower.includes('total') ||
      qLower.includes('pengeluaran') ||
      qLower.includes('biaya') ||
      qLower.includes('uang') ||
      qLower.includes('bbm') ||
      qLower.includes('hotel')
    ) {
      return this.handleFinancialQuery(rawQuery, qLower, dto, user, isPrivileged);
    }

    // 5. LPJ Completeness & Status Query
    if (
      qLower.includes('lpj') &&
      (qLower.includes('kurang') ||
        qLower.includes('lengkap') ||
        qLower.includes('kelengkapan') ||
        qLower.includes('belum') ||
        qLower.includes('status'))
    ) {
      return this.handleLpjCompletenessQuery(rawQuery, qLower, dto, user, isPrivileged);
    }

    // 6. Count Query ("Berapa kegiatan...", "Jumlah nota...")
    if (
      (qLower.startsWith('berapa') || qLower.startsWith('jumlah')) &&
      !qLower.includes('total') &&
      !qLower.includes('biaya') &&
      !qLower.includes('pengeluaran')
    ) {
      return this.handleCountQuery(rawQuery, qLower, dto, user, isPrivileged);
    }

    // 7. Report Draft Preparation Assistance
    if (
      qLower.includes('buat laporan') ||
      qLower.includes('draft laporan') ||
      qLower.includes('bantu buat laporan') ||
      qLower.includes('susun ringkasan')
    ) {
      return this.handleReportAssistance(rawQuery, dto, user, isPrivileged);
    }

    // 8. General / Contextual Unified Search
    return this.handleSearchQuery(rawQuery, qLower, dto, user, isPrivileged);
  }

  // --- PRIVATE HANDLERS ---

  private async handleDestructiveAction(
    query: string,
    dto: AssistantQueryDto,
  ): Promise<AssistantResponseDto> {
    return {
      message:
        'Tindakan penghapusan data membutuhkan konfirmasi manual Anda sesuai kebijakan Evidence & Data Governance Tulap.id.',
      intent: AssistantIntentEnum.DESTRUCTIVE_ACTION,
      sources: [],
      cards: [],
      suggestedActions: [
        {
          actionType: 'DELETE_CONFIRM',
          label: 'Hapus Data',
          entityId: dto.contextEntityId,
          isDestructive: true,
        },
      ],
      requiresConfirmation: true,
      confirmationAction: {
        actionType: 'DELETE_CONFIRM',
        label: 'Konfirmasi Hapus',
        entityId: dto.contextEntityId,
        isDestructive: true,
      },
    };
  }

  private async handleWriteAction(
    query: string,
    dto: AssistantQueryDto,
    user: AuthenticatedUser,
  ): Promise<AssistantResponseDto> {
    let taskName = 'Kegiatan Lapangan';
    let taskId = dto.contextEntityId;

    if (dto.contextEntityId) {
      const task = await this.prisma.task_SPPD.findUnique({
        where: { id: dto.contextEntityId },
      });
      if (task) {
        taskName = task.taskName;
        taskId = task.id;
      }
    }

    return {
      message: `Apakah Anda ingin menandai "${taskName}" sebagai selesai dan siap diajukan untuk verifikasi?`,
      intent: AssistantIntentEnum.WRITE_ACTION,
      sources: taskId
        ? [
            {
              id: taskId,
              title: taskName,
              entityType: 'ACTIVITY',
              referenceId: taskId,
            },
          ]
        : [],
      cards: [],
      suggestedActions: [
        {
          actionType: 'MARK_ACTIVITY_COMPLETE',
          label: 'Tandai Selesai',
          entityId: taskId,
          isDestructive: false,
        },
      ],
      requiresConfirmation: true,
      confirmationAction: {
        actionType: 'MARK_ACTIVITY_COMPLETE',
        label: 'Tandai Selesai',
        entityId: taskId,
        isDestructive: false,
      },
    };
  }

  private async resolveExactId(
    exactId: string,
    user: AuthenticatedUser,
    isPrivileged: boolean,
  ): Promise<AssistantResponseDto | null> {
    const idUpper = exactId.toUpperCase();

    // 1. Task ID
    const task = await this.prisma.task_SPPD.findFirst({
      where: {
        taskCode: idUpper,
        ...(isPrivileged
          ? {}
          : { OR: [{ assigneeId: user.id }, { creatorId: user.id }] }),
      },
    });

    if (task) {
      return {
        message: `Ditemukan kegiatan dengan kode resmi ${task.taskCode}: "${task.taskName}".`,
        intent: AssistantIntentEnum.NAVIGATION,
        sources: [
          {
            id: task.id,
            title: task.taskName,
            entityType: 'ACTIVITY',
            referenceId: task.taskCode,
          },
        ],
        cards: [
          {
            id: task.id,
            entityType: 'ACTIVITY',
            title: task.taskName,
            subtitle: `${task.taskCode} • ${task.destination}`,
            date: task.startDate.toISOString(),
            location: task.destination,
            status: task.status,
            badge: task.status,
            metadata: { taskCode: task.taskCode },
          },
        ],
        suggestedActions: [
          {
            actionType: 'OPEN_ACTIVITY',
            label: 'Buka Kegiatan',
            entityId: task.id,
          },
        ],
      };
    }

    // 2. Travel ID
    const travel = await this.prisma.travel_Mission.findFirst({
      where: {
        displayId: idUpper,
        ...(isPrivileged ? {} : { userId: user.id }),
      },
    });

    if (travel) {
      return {
        message: `Ditemukan Perjalanan Dinas ${travel.displayId}: "${travel.title}".`,
        intent: AssistantIntentEnum.NAVIGATION,
        sources: [
          {
            id: travel.id,
            title: travel.title,
            entityType: 'TRAVEL',
            referenceId: travel.displayId,
          },
        ],
        cards: [
          {
            id: travel.id,
            entityType: 'TRAVEL',
            title: travel.title,
            subtitle: `${travel.displayId} • ${travel.origin} → ${travel.destination}`,
            date: travel.departureDate.toISOString(),
            location: travel.destination,
            status: travel.status,
            badge: travel.status,
            metadata: { displayId: travel.displayId },
          },
        ],
        suggestedActions: [
          {
            actionType: 'OPEN_TRAVEL',
            label: 'Buka Perjalanan',
            entityId: travel.id,
          },
        ],
      };
    }

    return null;
  }

  private async handleFinancialQuery(
    rawQuery: string,
    qLower: string,
    dto: AssistantQueryDto,
    user: AuthenticatedUser,
    isPrivileged: boolean,
  ): Promise<AssistantResponseDto> {
    const expenseWhere: any = {};
    if (!isPrivileged) {
      expenseWhere.task = {
        OR: [{ assigneeId: user.id }, { creatorId: user.id }],
      };
    }

    // Filter by travel context or activity context if available
    if (dto.contextEntityType === AssistantContextEntityType.TRAVEL && dto.contextEntityId) {
      expenseWhere.task = {
        ...expenseWhere.task,
        travelMissionId: dto.contextEntityId,
      };
    } else if (
      dto.contextEntityType === AssistantContextEntityType.ACTIVITY &&
      dto.contextEntityId
    ) {
      expenseWhere.taskId = dto.contextEntityId;
    }

    // Filter by category if specified in query
    if (qLower.includes('bbm') || qLower.includes('bensin')) {
      expenseWhere.category = 'BBM';
    } else if (qLower.includes('hotel') || qLower.includes('penginapan')) {
      expenseWhere.category = 'PENGINAPAN';
    } else if (qLower.includes('konsumsi') || qLower.includes('makan')) {
      expenseWhere.category = 'KONSUMSI';
    } else if (qLower.includes('transport') || qLower.includes('tiket')) {
      expenseWhere.category = { in: ['TRANSPORTASI_LAIN', 'LAINNYA'] };
    }

    // Date range filter
    const dateRange = this.parseIndonesianDateRange(qLower);
    if (dateRange) {
      expenseWhere.transactionDate = {
        gte: dateRange.start,
        lte: dateRange.end,
      };
    }

    // AUTHORITATIVE CALCULATION: Only user-confirmed structured expense notes are included!
    // Draft OCR values that are not confirmed are excluded.
    const expenses = await this.prisma.expense_Note.findMany({
      where: expenseWhere,
      include: {
        task: { select: { id: true, taskName: true, taskCode: true, destination: true } },
      },
      orderBy: { totalAmount: 'desc' },
      take: 20,
    });

    const totalAmount = expenses.reduce((sum, e) => sum + Number(e.totalAmount), 0);
    const formattedTotal = rupiahFormatter.format(totalAmount);

    let message = '';
    if (expenses.length === 0) {
      message = 'Tidak ditemukan catatan pengeluaran terkonfirmasi yang sesuai kriteria.';
    } else if (qLower.includes('terbesar') || qLower.includes('paling besar')) {
      const largest = expenses[0];
      message = `Pengeluaran terbesar adalah "${largest.vendorName}" (${largest.category}) senilai ${rupiahFormatter.format(Number(largest.totalAmount))}.`;
    } else {
      let scopeLabel = '';
      if (expenseWhere.category) {
        scopeLabel = ` untuk kategori ${typeof expenseWhere.category === 'string' ? expenseWhere.category : 'Transportasi'}`;
      }
      if (dateRange?.label) {
        scopeLabel += ` pada ${dateRange.label}`;
      }
      message = `Total pengeluaran terkonfirmasi${scopeLabel} adalah ${formattedTotal} dari ${expenses.length} nota.`;
    }

    const cards: AssistantCardDto[] = expenses.slice(0, 5).map((e) => ({
      id: e.id,
      entityType: 'RECEIPT',
      title: e.vendorName,
      subtitle: `${e.category} • ${e.task?.taskCode || ''}`,
      date: e.transactionDate.toISOString(),
      amount: rupiahFormatter.format(Number(e.totalAmount)),
      status: e.verificationStatus,
      badge: e.category,
      metadata: { totalAmount: e.totalAmount.toString(), taskId: e.taskId },
    }));

    const sources: AssistantSourceDto[] = expenses.slice(0, 5).map((e) => ({
      id: e.id,
      title: `${e.vendorName} (${rupiahFormatter.format(Number(e.totalAmount))})`,
      entityType: 'RECEIPT',
      referenceId: e.id,
    }));

    return {
      message,
      intent: AssistantIntentEnum.TOTAL,
      sources,
      cards,
      suggestedActions: [
        {
          actionType: 'OPEN_SEARCH',
          label: 'Lihat Semua Nota',
          payload: { entityType: 'RECEIPT', query: rawQuery },
        },
      ],
    };
  }

  private async handleLpjCompletenessQuery(
    rawQuery: string,
    qLower: string,
    dto: AssistantQueryDto,
    user: AuthenticatedUser,
    isPrivileged: boolean,
  ): Promise<AssistantResponseDto> {
    const travelWhere: any = {};
    if (!isPrivileged) travelWhere.userId = user.id;

    if (dto.contextEntityType === AssistantContextEntityType.TRAVEL && dto.contextEntityId) {
      travelWhere.id = dto.contextEntityId;
    }

    const travels = await this.prisma.travel_Mission.findMany({
      where: travelWhere,
      include: {
        tasks: {
          include: {
            checklistItems: true,
            geotagPhotos: { select: { id: true } },
            expenseNotes: { select: { id: true, totalAmount: true } },
          },
        },
      },
      orderBy: { departureDate: 'desc' },
      take: 10,
    });

    if (travels.length === 0) {
      return {
        message: 'Tidak ditemukan data perjalanan dinas untuk evaluasi kelengkapan LPJ.',
        intent: AssistantIntentEnum.COMPLETENESS,
        sources: [],
        cards: [],
        suggestedActions: [],
      };
    }

    // Assess completeness authoritatively using business rule
    const incompleteLpjs: Array<{
      travel: any;
      score: number;
      missingItems: string[];
    }> = [];

    for (const tr of travels) {
      const missing: string[] = [];
      let totalItems = 0;
      let completedItems = 0;

      // 1. Check tasks completion
      if (tr.tasks.length === 0) {
        missing.push('Kegiatan Lapangan Terkait');
      } else {
        for (const t of tr.tasks) {
          totalItems += t.checklistItems.length;
          completedItems += t.checklistItems.filter((c) => c.isCompleted).length;
          if (t.geotagPhotos.length === 0) {
            missing.push(`Dokumentasi Foto (${t.taskCode})`);
          }
          if (t.expenseNotes.length === 0) {
            missing.push(`Nota Pengeluaran (${t.taskCode})`);
          }
        }
      }

      // Base supporting docs check
      if (!tr.assignmentLetterNumber) missing.push('Nomor Surat Tugas');

      const score =
        totalItems > 0
          ? Math.round((completedItems / Math.max(totalItems, 1)) * 100)
          : tr.tasks.length > 0
            ? 75
            : 40;

      if (score < 100 || missing.length > 0) {
        incompleteLpjs.push({ travel: tr, score, missingItems: missing });
      }
    }

    if (incompleteLpjs.length === 0) {
      return {
        message: 'Semua berkas LPJ perjalanan dinas Anda telah 100% lengkap dan terverifikasi.',
        intent: AssistantIntentEnum.COMPLETENESS,
        sources: travels.map((t) => ({
          id: t.id,
          title: t.title,
          entityType: 'LPJ',
          referenceId: t.displayId,
        })),
        cards: [],
        suggestedActions: [],
      };
    }

    const topIncomplete = incompleteLpjs[0];
    const missingBullets = topIncomplete.missingItems
      .slice(0, 4)
      .map((m) => `• ${m}`)
      .join('\n');

    const message = `LPJ untuk "${topIncomplete.travel.title}" (${topIncomplete.travel.displayId}) memiliki kelengkapan ${topIncomplete.score}%.\n\nDokumen/poin yang belum lengkap:\n${missingBullets}`;

    const cards: AssistantCardDto[] = incompleteLpjs.slice(0, 3).map((item) => ({
      id: item.travel.id,
      entityType: 'LPJ',
      title: item.travel.title,
      subtitle: `${item.travel.displayId} • Kelengkapan ${item.score}%`,
      date: item.travel.departureDate.toISOString(),
      location: item.travel.destination,
      status: 'INCOMPLETE',
      badge: `${item.score}%`,
      metadata: {
        missingItems: item.missingItems,
        displayId: item.travel.displayId,
      },
    }));

    const sources: AssistantSourceDto[] = incompleteLpjs.slice(0, 3).map((item) => ({
      id: item.travel.id,
      title: `${item.travel.title} (${item.score}%)`,
      entityType: 'LPJ',
      referenceId: item.travel.displayId,
    }));

    return {
      message,
      intent: AssistantIntentEnum.COMPLETENESS,
      sources,
      cards,
      suggestedActions: [
        {
          actionType: 'OPEN_LPJ',
          label: 'Buka Berkas LPJ',
          entityId: topIncomplete.travel.id,
        },
      ],
    };
  }

  private async handleCountQuery(
    rawQuery: string,
    qLower: string,
    dto: AssistantQueryDto,
    user: AuthenticatedUser,
    isPrivileged: boolean,
  ): Promise<AssistantResponseDto> {
    let entityLabel = 'data';
    let count = 0;
    const dateRange = this.parseIndonesianDateRange(qLower);

    if (qLower.includes('kegiatan') || qLower.includes('tugas')) {
      entityLabel = 'kegiatan';
      const taskWhere: any = {};
      if (!isPrivileged) taskWhere.OR = [{ assigneeId: user.id }, { creatorId: user.id }];
      if (dateRange) {
        taskWhere.startDate = { gte: dateRange.start, lte: dateRange.end };
      }
      count = await this.prisma.task_SPPD.count({ where: taskWhere });
    } else if (qLower.includes('perjalanan')) {
      entityLabel = 'perjalanan dinas';
      const travelWhere: any = {};
      if (!isPrivileged) travelWhere.userId = user.id;
      if (dateRange) {
        travelWhere.departureDate = { gte: dateRange.start, lte: dateRange.end };
      }
      count = await this.prisma.travel_Mission.count({ where: travelWhere });
    } else if (qLower.includes('nota') || qLower.includes('pengeluaran')) {
      entityLabel = 'nota pengeluaran';
      const expenseWhere: any = {};
      if (!isPrivileged) {
        expenseWhere.task = { OR: [{ assigneeId: user.id }, { creatorId: user.id }] };
      }
      if (dateRange) {
        expenseWhere.transactionDate = { gte: dateRange.start, lte: dateRange.end };
      }
      count = await this.prisma.expense_Note.count({ where: expenseWhere });
    } else if (qLower.includes('foto') || qLower.includes('bukti') || qLower.includes('dokumentasi')) {
      entityLabel = 'foto bukti geotag';
      const photoWhere: any = {};
      if (!isPrivileged) {
        photoWhere.task = { OR: [{ assigneeId: user.id }, { creatorId: user.id }] };
      }
      if (dateRange) {
        photoWhere.serverTimestamp = { gte: dateRange.start, lte: dateRange.end };
      }
      count = await this.prisma.geotag_Photo.count({ where: photoWhere });
    } else {
      const searchRes = await this.searchService.search(
        { q: rawQuery, limit: 100 },
        user,
      );
      count = searchRes.totalCount;
    }

    const timeContext = dateRange?.label ? ` pada ${dateRange.label}` : '';
    const message = `Terdapat ${count} ${entityLabel}${timeContext} yang tercatat pada sistem.`;

    return {
      message,
      intent: AssistantIntentEnum.COUNT,
      sources: [],
      cards: [],
      suggestedActions: [
        {
          actionType: 'OPEN_SEARCH',
          label: `Lihat ${entityLabel}`,
          payload: { query: rawQuery },
        },
      ],
    };
  }

  private async handleReportAssistance(
    rawQuery: string,
    dto: AssistantQueryDto,
    user: AuthenticatedUser,
    isPrivileged: boolean,
  ): Promise<AssistantResponseDto> {
    let task: any = null;
    if (dto.contextEntityId) {
      task = await this.prisma.task_SPPD.findUnique({
        where: { id: dto.contextEntityId },
        include: {
          geotagPhotos: { select: { id: true, caption: true, address: true } },
          expenseNotes: { select: { id: true, vendorName: true, totalAmount: true } },
        },
      });
    }

    if (!task) {
      task = await this.prisma.task_SPPD.findFirst({
        where: isPrivileged
          ? {}
          : { OR: [{ assigneeId: user.id }, { creatorId: user.id }] },
        orderBy: { startDate: 'desc' },
        include: {
          geotagPhotos: { select: { id: true, caption: true, address: true } },
          expenseNotes: { select: { id: true, vendorName: true, totalAmount: true } },
        },
      });
    }

    if (!task) {
      return {
        message: 'Belum ada kegiatan yang dapat dijadikan draft laporan.',
        intent: AssistantIntentEnum.REPORT_ASSISTANCE,
        sources: [],
        cards: [],
        suggestedActions: [],
      };
    }

    const message = `Draft laporan kegiatan "${task.taskName}" (${task.taskCode}) telah disiapkan berdasarkan ${task.geotagPhotos.length} foto bukti dan ${task.expenseNotes.length} nota pengeluaran. Anda dapat meninjau dan mengedit sebelum memfinalisasi.`;

    return {
      message,
      intent: AssistantIntentEnum.REPORT_ASSISTANCE,
      sources: [
        {
          id: task.id,
          title: task.taskName,
          entityType: 'REPORT',
          referenceId: task.taskCode,
        },
      ],
      cards: [
        {
          id: task.id,
          entityType: 'ACTIVITY',
          title: task.taskName,
          subtitle: `${task.taskCode} • ${task.destination}`,
          date: task.startDate.toISOString(),
          location: task.destination,
          status: 'DRAFT',
          badge: 'Draft Laporan',
        },
      ],
      suggestedActions: [
        {
          actionType: 'PREPARE_REPORT',
          label: 'Pratinjau Draft Laporan',
          entityId: task.id,
        },
      ],
    };
  }

  private async handleSearchQuery(
    rawQuery: string,
    qLower: string,
    dto: AssistantQueryDto,
    user: AuthenticatedUser,
    isPrivileged: boolean,
  ): Promise<AssistantResponseDto> {
    // Determine entity type filter from keywords
    let entityTypes: SearchEntityTypeEnum[] | undefined;
    if (qLower.includes('kegiatan') || qLower.includes('tugas')) {
      entityTypes = [SearchEntityTypeEnum.ACTIVITY];
    } else if (qLower.includes('perjalanan') || qLower.includes('sppd')) {
      entityTypes = [SearchEntityTypeEnum.TRAVEL];
    } else if (qLower.includes('nota') || qLower.includes('struk')) {
      entityTypes = [SearchEntityTypeEnum.RECEIPT];
    } else if (qLower.includes('foto') || qLower.includes('bukti') || qLower.includes('dokumentasi')) {
      entityTypes = [SearchEntityTypeEnum.EVIDENCE];
    } else if (qLower.includes('lpj')) {
      entityTypes = [SearchEntityTypeEnum.LPJ];
    }

    // Reuse Phase 10 Search Engine directly!
    const searchRes = await this.searchService.search(
      {
        q: rawQuery,
        entityTypes,
        limit: 10,
      },
      user,
    );

    const cards: AssistantCardDto[] = searchRes.items.slice(0, 5).map((item) => ({
      id: item.entityId,
      entityType: item.entityType,
      title: item.title,
      subtitle: item.subtitle ?? undefined,
      date: item.date,
      location: item.location ?? undefined,
      amount: item.metadata?.totalAmount
        ? rupiahFormatter.format(Number(item.metadata.totalAmount))
        : item.metadata?.budgetAmount
          ? rupiahFormatter.format(Number(item.metadata.budgetAmount))
          : undefined,
      status: item.metadata?.status,
      badge: item.entityType,
      metadata: item.metadata ?? undefined,
    }));

    const sources: AssistantSourceDto[] = searchRes.items.slice(0, 5).map((item) => ({
      id: item.entityId,
      title: item.title,
      entityType: item.entityType,
      referenceId: item.entityId,
    }));

    let synthesisText = '';
    if (searchRes.items.length === 0) {
      synthesisText = `Saya tidak menemukan data yang sesuai untuk pencarian "${rawQuery}".`;
    } else {
      synthesisText = await this.languageModel.synthesizeAnswer({
        query: rawQuery,
        minimalRecords: searchRes.items.slice(0, 4).map((i) => ({
          type: i.entityType,
          title: i.title,
          date: i.date,
          location: i.location ?? undefined,
          status: i.metadata?.status,
        })),
      });
    }

    const suggestedActions: AssistantActionDto[] = [];
    if (searchRes.items.length > 0) {
      const first = searchRes.items[0];
      let actType: AssistantActionDto['actionType'] = 'OPEN_ACTIVITY';
      if (first.entityType === 'TRAVEL') actType = 'OPEN_TRAVEL';
      if (first.entityType === 'RECEIPT') actType = 'OPEN_RECEIPT';
      if (first.entityType === 'LPJ') actType = 'OPEN_LPJ';
      if (first.entityType === 'EVIDENCE') actType = 'OPEN_EVIDENCE';

      suggestedActions.push({
        actionType: actType,
        label: `Buka ${first.title}`,
        entityId: first.entityId,
      });

      if (searchRes.totalCount > 5) {
        suggestedActions.push({
          actionType: 'OPEN_SEARCH',
          label: `Lihat Semua (${searchRes.totalCount} data)`,
          payload: { query: rawQuery, entityType: entityTypes?.[0] },
        });
      }
    }

    return {
      message: synthesisText,
      intent: AssistantIntentEnum.SEARCH,
      sources,
      cards,
      suggestedActions,
    };
  }

  private parseIndonesianDateRange(
    qLower: string,
  ): { start: Date; end: Date; label: string } | null {
    const now = new Date();

    if (qLower.includes('hari ini')) {
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
      const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
      return { start, end, label: 'Hari Ini' };
    }

    if (qLower.includes('kemarin')) {
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1, 0, 0, 0);
      const end = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 1, 23, 59, 59);
      return { start, end, label: 'Kemarin' };
    }

    if (qLower.includes('minggu ini')) {
      const day = now.getDay() || 7;
      const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - day + 1, 0, 0, 0);
      const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
      return { start, end, label: 'Minggu Ini' };
    }

    if (qLower.includes('bulan ini')) {
      const start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);
      const end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);
      return { start, end, label: 'Bulan Ini' };
    }

    if (qLower.includes('bulan lalu')) {
      const start = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0);
      const end = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59);
      return { start, end, label: 'Bulan Lalu' };
    }

    if (qLower.includes('agustus 2026') || qLower.includes('agustus')) {
      const year = qLower.includes('2026') ? 2026 : now.getFullYear();
      const start = new Date(year, 7, 1, 0, 0, 0);
      const end = new Date(year, 7, 31, 23, 59, 59);
      return { start, end, label: `Agustus ${year}` };
    }

    return null;
  }
}
