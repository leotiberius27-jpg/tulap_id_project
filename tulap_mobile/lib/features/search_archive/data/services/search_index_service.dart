import 'package:sqflite/sqflite.dart';
import '../../../../core/database/local_database.dart';
import '../../domain/entities/search_result_entity.dart';
import '../models/search_result_model.dart';

class SearchIndexService {
  Future<Database> get _db => LocalDatabase.instance;

  /// Backfill semua data historis Phase 1–9 ke tabel proyeksi `search_index`
  Future<int> backfillAll() async {
    final db = await _db;
    int indexedCount = 0;

    // 1. Index Activities / Tasks
    try {
      final taskRows = await db.query('tasks');
      for (final row in taskRows) {
        final entityId = row['id'] as String;
        final title = row['title'] as String? ?? 'Kegiatan Tanpa Judul';
        final code = row['taskCode'] as String? ?? '';
        final location = row['destination'] as String? ?? '';
        final dateStr = row['startDate'] as String? ?? row['createdAt'] as String? ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
        final status = row['status'] as String? ?? '';
        final budget = row['budgetAmount']?.toString() ?? '0';

        final model = SearchResultModel(
          entityId: entityId,
          entityType: SearchEntityType.activity,
          title: title,
          subtitle: '$code • $location',
          date: date,
          location: location,
          parentId: row['travelId'] as String?,
          syncStatus: row['syncStatus'] as String? ?? 'SYNCED',
          metadata: {
            'taskCode': code,
            'status': status,
            'budgetAmount': budget,
            'assigneeName': row['assigneeName'],
          },
        );

        await db.insert(
          'search_index',
          model.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        indexedCount++;
      }
    } catch (_) {}

    // 2. Index Travel Missions
    try {
      final travelRows = await db.query('travel_missions');
      for (final row in travelRows) {
        final entityId = row['id'] as String;
        final title = row['title'] as String? ?? 'Perjalanan Dinas';
        final displayId = row['displayId'] as String? ?? '';
        final origin = row['origin'] as String? ?? '';
        final dest = row['destination'] as String? ?? '';
        final letter = row['assignmentLetterNumber'] as String? ?? '';
        final depStr = row['departureDate'] as String? ?? '';
        final date = DateTime.tryParse(depStr) ?? DateTime.now();

        final model = SearchResultModel(
          entityId: entityId,
          entityType: SearchEntityType.travel,
          title: title,
          subtitle: '$displayId • $origin → $dest',
          date: date,
          location: dest,
          syncStatus: row['syncStatus'] as String? ?? 'LOCAL_ONLY',
          metadata: {
            'displayId': displayId,
            'assignmentLetterNumber': letter,
            'status': row['status'],
            'transportMode': row['transportMode'],
            'origin': origin,
            'destination': dest,
          },
        );

        await db.insert(
          'search_index',
          model.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        indexedCount++;
      }
    } catch (_) {}

    // 3. Index Geotag Photos & Evidence
    try {
      final photoRows = await db.query('geotag_photos');
      for (final row in photoRows) {
        final entityId = row['id'] as String;
        final caption = row['caption'] as String?;
        final address = row['address'] as String?;
        final dateStr = row['serverTimestamp'] as String? ?? row['deviceTimestamp'] as String? ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
        final taskId = row['taskId'] as String;

        final model = SearchResultModel(
          entityId: entityId,
          entityType: SearchEntityType.evidence,
          title: caption?.isNotEmpty == true ? caption! : 'Foto Bukti Geotag',
          subtitle: address ?? 'Lokasi Terverifikasi',
          date: date,
          location: address,
          localThumbnailPath: row['localFilePath'] as String?,
          parentId: taskId,
          syncStatus: row['syncStatus'] as String? ?? 'LOCAL_ONLY',
          metadata: {
            'latitude': row['latitude']?.toString(),
            'longitude': row['longitude']?.toString(),
            'integrityHash': row['integrityHash'],
            'mediaType': row['mediaType'],
          },
        );

        await db.insert(
          'search_index',
          model.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        indexedCount++;
      }
    } catch (_) {}

    // 4. Index Expense Notes & OCR Receipts
    try {
      final expenseRows = await db.query('expense_notes');
      for (final row in expenseRows) {
        final entityId = row['id'] as String;
        final vendor = row['vendorName'] as String? ?? 'Nota Belanja';
        final category = row['category'] as String? ?? 'LAINNYA';
        final amount = (row['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final dateStr = row['transactionDate'] as String? ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
        final ocrText = row['ocrRawText'] as String? ?? '';

        final model = SearchResultModel(
          entityId: entityId,
          entityType: SearchEntityType.receipt,
          title: vendor,
          subtitle: '$category • Rp ${amount.toInt()}',
          date: date,
          localThumbnailPath: row['localScanPath'] as String?,
          parentId: row['taskId'] as String?,
          syncStatus: row['syncStatus'] as String? ?? 'LOCAL_ONLY',
          metadata: {
            'category': category,
            'totalAmount': amount.toString(),
            'vendorName': vendor,
            'ocrRawText': ocrText,
            'receiptNumber': row['receiptNumber'],
            'travelId': row['travelId'],
          },
        );

        await db.insert(
          'search_index',
          model.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        indexedCount++;
      }
    } catch (_) {}

    // 5. Index Reports
    try {
      final reportRows = await db.query('activity_reports');
      for (final row in reportRows) {
        final entityId = row['id'] as String;
        final title = row['title'] as String? ?? 'Laporan Kegiatan';
        final code = row['reportCode'] as String? ?? '';
        final dateStr = row['generatedAt'] as String? ?? row['createdAt'] as String? ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();

        final model = SearchResultModel(
          entityId: entityId,
          entityType: SearchEntityType.report,
          title: title,
          subtitle: '$code (v${row['versionNumber'] ?? 1})',
          date: date,
          parentId: row['taskId'] as String?,
          syncStatus: row['syncStatus'] as String? ?? 'LOCAL_ONLY',
          metadata: {
            'reportCode': code,
            'versionNumber': row['versionNumber'],
            'pdfLocalPath': row['pdfLocalPath'],
            'sha256': row['reportSha256'],
          },
        );

        await db.insert(
          'search_index',
          model.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        indexedCount++;
      }
    } catch (_) {}

    // 6. Index Supporting Documents
    try {
      final docRows = await db.query('supporting_documents');
      for (final row in docRows) {
        final entityId = row['id'] as String;
        final title = row['title'] as String? ?? 'Dokumen Pendukung';
        final type = row['documentType'] as String? ?? '';
        final dateStr = row['createdAt'] as String? ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();

        final model = SearchResultModel(
          entityId: entityId,
          entityType: SearchEntityType.document,
          title: title,
          subtitle: type,
          date: date,
          localThumbnailPath: row['filePath'] as String?,
          parentId: row['travelMissionId'] as String?,
          syncStatus: row['syncStatus'] as String? ?? 'LOCAL_ONLY',
          metadata: {
            'documentType': type,
            'sha256': row['sha256'],
          },
        );

        await db.insert(
          'search_index',
          model.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        indexedCount++;
      }
    } catch (_) {}

    // 7. Index LPJ Packages
    try {
      final lpjRows = await db.query('lpj_packages');
      for (final row in lpjRows) {
        final entityId = row['id'] as String;
        final title = row['title'] as String? ?? 'Paket LPJ Resmi';
        final code = row['packageCode'] as String? ?? '';
        final dateStr = row['createdAt'] as String? ?? '';
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();

        final model = SearchResultModel(
          entityId: entityId,
          entityType: SearchEntityType.lpj,
          title: title,
          subtitle: '$code • Lengkap',
          date: date,
          parentId: row['travelMissionId'] as String?,
          syncStatus: row['syncStatus'] as String? ?? 'LOCAL_ONLY',
          metadata: {
            'packageCode': code,
            'versionNumber': row['versionNumber'],
            'pdfLocalPath': row['pdfLocalPath'],
            'completenessScore': row['completenessScore'],
            'totalActualExpense': row['totalActualExpense'],
          },
        );

        await db.insert(
          'search_index',
          model.toSqlite(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        indexedCount++;
      }
    } catch (_) {}

    return indexedCount;
  }

  /// Rebuild indeks pencarian lokal tanpa menghapus data sumber asli
  Future<void> rebuildIndex() async {
    final db = await _db;
    await db.delete('search_index');
    await backfillAll();
  }

  /// Update / Insert spesifik per rekaman baru
  Future<void> upsertIndexItem(SearchResultModel item) async {
    final db = await _db;
    await db.insert(
      'search_index',
      item.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Hapus rekaman dari indeks jika dihapus dari sistem
  Future<void> deleteIndexItem(String entityId) async {
    final db = await _db;
    await db.delete('search_index', where: 'entityId = ?', whereArgs: [entityId]);
  }
}
