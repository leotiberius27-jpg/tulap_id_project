import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/network/dio_client.dart';
import '../../../expense_ocr/data/models/expense_note_model.dart';
import '../../../geotag_camera/data/models/geotag_photo_model.dart';
import '../../domain/entities/sync_record_entity.dart';

/// SyncRemoteDataSource
/// ----------------------------------------------------------------------
/// Bertanggung jawab menerjemahkan satu SyncRecordEntity menjadi
/// request HTTP nyata ke backend, sesuai `entityType`-nya. Endpoint
/// yang dipakai mengacu ke API Domain Recommendation (Bagian 29
/// dokumen spesifikasi): POST /evidence/photo, POST /evidence/receipt,
/// dsb.
///
/// PENTING - Rekonsiliasi server timestamp: saat upload foto berhasil,
/// response dari backend membawa `serverTimestamp` YANG SEBENARNYA
/// (dicatat oleh server saat request diterima, bukan jam device saat
/// capture). Ini menutup catatan tertunda dari GeotagCameraRepositoryImpl
/// yang sebelumnya memakai jam device sebagai fallback offline.
/// ----------------------------------------------------------------------
class SyncRemoteDataSource {
  final DioClient _dioClient;
  final Database _database; // Untuk baca file terkait & update server timestamp

  SyncRemoteDataSource({
    required DioClient dioClient,
    required Database database,
  }) : _dioClient = dioClient,
       _database = database;

  /// Mengunggah satu record sesuai jenisnya. Melempar [DioException]
  /// apa adanya jika gagal - ditangkap & diterjemahkan jadi status oleh
  /// SyncQueueRepositoryImpl.
  Future<void> uploadRecord(SyncRecordEntity record) async {
    switch (record.entityType) {
      case SyncEntityType.geotagPhoto:
        await _uploadGeotagPhoto(record);
        break;
      case SyncEntityType.expenseNote:
        await _uploadExpenseNote(record);
        break;
      case SyncEntityType.taskChecklist:
        await _uploadTaskChecklist(record);
        break;
    }
  }

  Future<void> _uploadGeotagPhoto(SyncRecordEntity record) async {
    final rows = await _database.query(
      'geotag_photos',
      where: 'id = ?',
      whereArgs: [record.entityLocalId],
    );
    if (rows.isEmpty) {
      throw Exception('Data foto lokal tidak ditemukan untuk sinkronisasi.');
    }

    final photo = GeotagPhotoModel.fromJson(rows.first);

    final formData = FormData.fromMap({
      ...photo.toUploadPayload(),
      'file': await MultipartFile.fromFile(
        photo.localFilePath,
        filename: '${photo.id}.jpg',
      ),
    });

    final response = await _dioClient.dio.post(
      '/evidence/photo',
      data: formData,
      options: Options(headers: {'X-Idempotency-Key': record.id}),
    );

    // Rekonsiliasi: timpa serverTimestamp lokal dengan waktu resmi
    // dari server, sesuai catatan tertunda di GeotagCameraRepositoryImpl.
    final authoritativeTimestamp = response.data['serverTimestamp'] as String?;
    if (authoritativeTimestamp != null) {
      await _database.update(
        'geotag_photos',
        {'serverTimestamp': authoritativeTimestamp},
        where: 'id = ?',
        whereArgs: [photo.id],
      );
    }
  }

  Future<void> _uploadExpenseNote(SyncRecordEntity record) async {
    final rows = await _database.query(
      'expense_notes',
      where: 'id = ?',
      whereArgs: [record.entityLocalId],
    );
    if (rows.isEmpty) {
      throw Exception('Data nota lokal tidak ditemukan untuk sinkronisasi.');
    }

    final note = ExpenseNoteModel.fromMap(rows.first);

    final formData = FormData.fromMap({
      ...note.toUploadPayload(),
      'file': await MultipartFile.fromFile(
        note.localScanPath,
        filename: '${note.id}.jpg',
      ),
    });

    // Backend melakukan pengecekan duplikat FINAL di sisi server (mis.
    // berdasar hash vendor+tanggal+nominal per instansi) - deteksi di
    // mobile (ExpenseOcrLocalDataSource.findDuplicateNoteId) hanya
    // peringatan dini lokal, bukan validasi otoritatif. Jika server
    // membalas 409, error ini akan diterjemahkan jadi pesan yang sudah
    // manusiawi oleh SyncQueueRepositoryImpl._mapDioErrorToUserMessage.
    await _dioClient.dio.post(
      '/evidence/receipt',
      data: formData,
      options: Options(headers: {'X-Idempotency-Key': record.id}),
    );
  }

  Future<void> _uploadTaskChecklist(SyncRecordEntity record) async {
    final rows = await _database.query(
      'task_checklist_items',
      where: 'id = ?',
      whereArgs: [record.entityLocalId],
    );
    if (rows.isEmpty) {
      throw Exception(
        'Item checklist lokal tidak ditemukan untuk sinkronisasi.',
      );
    }

    final isCompleted = rows.first['isCompleted'] == 1;

    // Endpoint checklist berbeda dari foto/nota - tidak ada file untuk
    // diunggah, jadi request biasa (bukan multipart) sudah cukup.
    await _dioClient.dio.patch(
      '/tasks/${record.taskId}/checklist/${record.entityLocalId}',
      data: {'isCompleted': isCompleted},
      options: Options(headers: {'X-Idempotency-Key': record.id}),
    );
  }
}
