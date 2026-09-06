import '../../../../core/database/local_database.dart';
import '../../../search_archive/domain/entities/search_filter_state.dart';
import '../../../search_archive/domain/entities/search_result_entity.dart';
import '../../../search_archive/domain/repositories/search_archive_repository.dart';
import '../../domain/entities/assistant_message_entity.dart';

abstract class AssistantLocalDataSource {
  Future<AssistantMessageEntity> queryOffline({
    required String text,
    String? contextEntityType,
    String? contextEntityId,
  });

  List<String> getSuggestedQuestions({
    String? contextEntityType,
    String? contextEntityId,
  });
}

class AssistantLocalDataSourceImpl implements AssistantLocalDataSource {
  final SearchArchiveRepository searchArchiveRepository;

  AssistantLocalDataSourceImpl({
    required this.searchArchiveRepository,
  });

  @override
  List<String> getSuggestedQuestions({
    String? contextEntityType,
    String? contextEntityId,
  }) {
    if (contextEntityType == 'ACTIVITY') {
      return [
        'Ringkas kegiatan ini',
        'Lihat foto dokumentasi',
        'Bantu buat laporan',
        'Cari nota kegiatan ini',
      ];
    }

    if (contextEntityType == 'TRAVEL') {
      return [
        'Ringkas perjalanan ini',
        'Total pengeluaran perjalanan',
        'Apa yang kurang dari LPJ?',
        'Lihat kegiatan perjalanan',
      ];
    }

    if (contextEntityType == 'LPJ') {
      return [
        'Apa yang kurang dari LPJ?',
        'Berapa kelengkapannya?',
        'Buka dokumen pendukung',
        'Ringkas perjalanan',
      ];
    }

    if (contextEntityType == 'RECEIPT') {
      return [
        'Lihat kegiatan terkait',
        'Tampilkan pengeluaran perjalanan',
        'Buka foto nota',
      ];
    }

    // Default Home Suggestions
    return [
      'Kegiatan saya hari ini',
      'Cari kegiatan',
      'LPJ belum lengkap',
      'Nota yang belum diperiksa',
      'Bukti belum tersinkronisasi',
    ];
  }

  @override
  Future<AssistantMessageEntity> queryOffline({
    required String text,
    String? contextEntityType,
    String? contextEntityId,
  }) async {
    final qLower = text.toLowerCase().trim();

    // 1. Destructive action
    if (qLower.contains('hapus foto') ||
        qLower.contains('hapus kegiatan') ||
        qLower.contains('hapus nota') ||
        qLower.contains('hapus semua')) {
      return AssistantMessageEntity(
        id: 'msg_off_${DateTime.now().millisecondsSinceEpoch}',
        sender: AssistantSender.tulap,
        text:
            'Tindakan penghapusan data membutuhkan konfirmasi manual Anda sesuai kebijakan Evidence & Data Governance Tulap.id.',
        timestamp: DateTime.now(),
        requiresConfirmation: true,
        confirmationAction: AssistantActionEntity(
          actionType: AssistantActionType.deleteConfirm,
          label: 'Konfirmasi Hapus',
          entityId: contextEntityId,
          isDestructive: true,
        ),
        isOffline: true,
      );
    }

    // 2. Write action
    if (qLower.contains('selesaikan kegiatan') ||
        qLower.contains('tandai selesai')) {
      return AssistantMessageEntity(
        id: 'msg_off_${DateTime.now().millisecondsSinceEpoch}',
        sender: AssistantSender.tulap,
        text:
            'Kegiatan lapangan akan ditandai sebagai selesai secara lokal dan disinkronkan saat online.',
        timestamp: DateTime.now(),
        requiresConfirmation: true,
        confirmationAction: AssistantActionEntity(
          actionType: AssistantActionType.markActivityComplete,
          label: 'Tandai Selesai',
          entityId: contextEntityId,
          isDestructive: false,
        ),
        isOffline: true,
      );
    }

    // 3. Search locally using Phase 10 SearchArchiveRepository
    SearchEntityType? entityType;
    if (qLower.contains('kegiatan') || qLower.contains('tugas')) {
      entityType = SearchEntityType.activity;
    } else if (qLower.contains('perjalanan')) {
      entityType = SearchEntityType.travel;
    } else if (qLower.contains('nota') || qLower.contains('struk')) {
      entityType = SearchEntityType.receipt;
    } else if (qLower.contains('foto') || qLower.contains('bukti')) {
      entityType = SearchEntityType.evidence;
    } else if (qLower.contains('lpj')) {
      entityType = SearchEntityType.lpj;
    }

    final searchResult = await searchArchiveRepository.search(
      query: text,
      filter: SearchFilterState(selectedType: entityType),
      forceOffline: true,
    );

    final items = searchResult.fold(
      (_) => <SearchResultEntity>[],
      (r) => r,
    );

    if (items.isEmpty) {
      return AssistantMessageEntity(
        id: 'msg_off_${DateTime.now().millisecondsSinceEpoch}',
        sender: AssistantSender.tulap,
        text:
            'Saya tidak menemukan data di perangkat untuk "$text". Sebagian riwayat hanya tersedia saat perangkat terhubung ke internet.',
        timestamp: DateTime.now(),
        isOffline: true,
      );
    }

    final cards = items.take(5).map((i) {
      return AssistantCardEntity(
        id: i.entityId,
        entityType: _mapEntityTypeToString(i.entityType),
        title: i.title,
        subtitle: i.subtitle,
        date: i.date,
        location: i.location,
        amount: i.metadata?['totalAmount'] != null
            ? 'Rp ${i.metadata!['totalAmount']}'
            : null,
        status: i.metadata?['status']?.toString(),
        badge: _mapEntityTypeToString(i.entityType),
        metadata: i.metadata,
      );
    }).toList();

    final sources = items.take(5).map((i) {
      return AssistantSourceEntity(
        id: i.entityId,
        title: i.title,
        entityType: _mapEntityTypeToString(i.entityType),
        referenceId: i.entityId,
      );
    }).toList();

    final first = items.first;
    final suggestedActions = <AssistantActionEntity>[
      AssistantActionEntity(
        actionType: _mapEntityTypeToAction(first.entityType),
        label: 'Buka ${first.title}',
        entityId: first.entityId,
      ),
    ];

    if (items.length > 5) {
      suggestedActions.add(
        AssistantActionEntity(
          actionType: AssistantActionType.openSearch,
          label: 'Lihat Semua (${items.length} data)',
          payload: {'query': text},
        ),
      );
    }

    final messageText =
        'Saya menemukan ${items.length} data di perangkat.\n\nCatatan: Ringkasan AI membutuhkan koneksi internet.';

    return AssistantMessageEntity(
      id: 'msg_off_${DateTime.now().millisecondsSinceEpoch}',
      sender: AssistantSender.tulap,
      text: messageText,
      timestamp: DateTime.now(),
      cards: cards,
      sources: sources,
      suggestedActions: suggestedActions,
      isOffline: true,
    );
  }

  String _mapEntityTypeToString(SearchEntityType type) {
    switch (type) {
      case SearchEntityType.activity:
        return 'ACTIVITY';
      case SearchEntityType.travel:
        return 'TRAVEL';
      case SearchEntityType.evidence:
        return 'EVIDENCE';
      case SearchEntityType.receipt:
      case SearchEntityType.expense:
        return 'RECEIPT';
      case SearchEntityType.report:
        return 'REPORT';
      case SearchEntityType.document:
        return 'DOCUMENT';
      case SearchEntityType.lpj:
        return 'LPJ';
    }
  }

  AssistantActionType _mapEntityTypeToAction(SearchEntityType type) {
    switch (type) {
      case SearchEntityType.activity:
        return AssistantActionType.openActivity;
      case SearchEntityType.travel:
        return AssistantActionType.openTravel;
      case SearchEntityType.evidence:
        return AssistantActionType.openEvidence;
      case SearchEntityType.receipt:
      case SearchEntityType.expense:
        return AssistantActionType.openReceipt;
      case SearchEntityType.report:
        return AssistantActionType.openReport;
      case SearchEntityType.lpj:
        return AssistantActionType.openLpj;
      case SearchEntityType.document:
        return AssistantActionType.openSearch;
    }
  }
}
