import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/network/dio_client.dart';
import '../../../expense_ocr/data/models/expense_note_model.dart';
import '../../../geotag_camera/data/models/geotag_photo_model.dart';
import '../../../travel_mission/data/models/lpj_package_model.dart';
import '../../../travel_mission/data/models/supporting_document_model.dart';
import '../../../travel_mission/data/models/travel_mission_model.dart';
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
      case SyncEntityType.activityReport:
        await _uploadActivityReport(record);
        break;
      case SyncEntityType.travelMission:
        await _uploadTravelMission(record);
        break;
      case SyncEntityType.supportingDocument:
        await _uploadSupportingDocument(record);
        break;
      case SyncEntityType.lpjPackage:
        await _uploadLpjPackage(record);
        break;
      case SyncEntityType.securityEvent:
        await _uploadSecurityEvent(record);
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
    final isVideo = photo.isVideo;
    final extension = isVideo ? 'mp4' : 'jpg';

    final formData = FormData.fromMap({
      ...photo.toUploadPayload(),
      'id': photo.id,
      'file': await MultipartFile.fromFile(
        photo.localFilePath,
        filename: '${photo.id}.$extension',
      ),
    });

    final response = await _dioClient.dio.post(
      '/evidence/photo',
      data: formData,
      options: Options(headers: {'X-Idempotency-Key': record.id}),
    );

    // Rekonsiliasi: timpa serverTimestamp lokal dengan waktu resmi
    // dari server dan update status sinkronisasi ke SYNCED
    final authoritativeTimestamp = response.data['serverTimestamp'] as String?;
    await _database.update(
      'geotag_photos',
      {
        if (authoritativeTimestamp != null)
          'serverTimestamp': authoritativeTimestamp,
        'syncStatus': 'SYNCED',
        'verificationStatus': 'SYNCED',
      },
      where: 'id = ?',
      whereArgs: [photo.id],
    );
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

    final payload = Map<String, dynamic>.from(note.toUploadPayload());
    final fileExists = note.localScanPath.isNotEmpty &&
        await File(note.localScanPath).exists();

    if (fileExists) {
      payload['file'] = await MultipartFile.fromFile(
        note.localScanPath,
        filename: '${note.id}.jpg',
      );
    }

    final formData = FormData.fromMap(payload);

    final response = await _dioClient.dio.post(
      '/evidence/receipt',
      data: formData,
      options: Options(headers: {'X-Idempotency-Key': record.id}),
    );

    final authoritativeTimestamp = response.data['serverTimestamp'] as String?;
    final remoteUrl = response.data['scanUrl'] as String?;

    await _database.update(
      'expense_notes',
      {
        if (authoritativeTimestamp != null)
          'serverTimestamp': authoritativeTimestamp,
        if (remoteUrl != null && remoteUrl.isNotEmpty)
          'remoteScanUrl': remoteUrl,
        'syncStatus': 'SYNCED',
        'verificationStatus': 'synced',
      },
      where: 'id = ?',
      whereArgs: [note.id],
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

  Future<void> _uploadActivityReport(SyncRecordEntity record) async {
    final rows = await _database.query(
      'activity_reports',
      where: 'id = ?',
      whereArgs: [record.entityLocalId],
    );
    if (rows.isEmpty) {
      throw Exception('Data laporan kegiatan lokal tidak ditemukan untuk sinkronisasi.');
    }

    final row = rows.first;
    final pdfPath = row['pdfLocalPath'] as String?;
    final reportCode = row['reportCode'] as String? ?? 'report';

    final payload = <String, dynamic>{
      'id': row['id'],
      'taskId': row['taskId'],
      'reportCode': row['reportCode'],
      'title': row['title'],
      'reportType': row['reportType'],
      'templateId': row['templateId'],
      'templateVersion': row['templateVersion'],
      'versionNumber': row['versionNumber'],
      'reportSha256': row['reportSha256'],
      'summary': row['summary'],
      'narrative': row['narrative'],
      'contentSnapshotJson': row['contentSnapshotJson'],
      'totalExpense': row['totalExpense'],
      'evidenceCount': row['evidenceCount'],
      'receiptCount': row['receiptCount'],
    };

    if (pdfPath != null && pdfPath.isNotEmpty && File(pdfPath).existsSync()) {
      payload['file'] = await MultipartFile.fromFile(
        pdfPath,
        filename: '$reportCode.pdf',
      );
    }

    final formData = FormData.fromMap(payload);

    final response = await _dioClient.dio.post(
      '/lpj/report/upload',
      data: formData,
      options: Options(headers: {'X-Idempotency-Key': record.id}),
    );

    final serverTimestamp = response.data['serverTimestamp'] as String?;
    final pdfRemoteUrl = response.data['pdfRemoteUrl'] as String?;

    await _database.update(
      'activity_reports',
      {
        'syncStatus': 'SYNCED',
        if (serverTimestamp != null) 'serverTimestamp': serverTimestamp,
        if (pdfRemoteUrl != null && pdfRemoteUrl.isNotEmpty) 'pdfRemoteUrl': pdfRemoteUrl,
      },
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<void> _uploadTravelMission(SyncRecordEntity record) async {
    final rows = await _database.query(
      'travel_missions',
      where: 'id = ?',
      whereArgs: [record.entityLocalId],
    );
    if (rows.isEmpty) return;

    final mission = TravelMissionModel.fromJson(rows.first);
    await _dioClient.dio.post(
      '/travel',
      data: mission.toApiPayload(),
      options: Options(headers: {'X-Idempotency-Key': record.id}),
    );

    await _database.update(
      'travel_missions',
      {'syncStatus': 'SYNCED'},
      where: 'id = ?',
      whereArgs: [mission.id],
    );
  }

  Future<void> _uploadSupportingDocument(SyncRecordEntity record) async {
    final rows = await _database.query(
      'supporting_documents',
      where: 'id = ?',
      whereArgs: [record.entityLocalId],
    );
    if (rows.isEmpty) return;

    final doc = SupportingDocumentModel.fromJson(rows.first);
    final file = File(doc.filePath);
    final fileName = doc.filePath.split(Platform.pathSeparator).last;

    final formData = FormData.fromMap({
      ...doc.toApiPayload(),
      if (file.existsSync())
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
    });

    final response = await _dioClient.dio.post(
      '/travel/document',
      data: formData,
      options: Options(headers: {'X-Idempotency-Key': record.id}),
    );

    final remoteUrl = response.data['documentUrl'] as String?;
    await _database.update(
      'supporting_documents',
      {
        'syncStatus': 'SYNCED',
        if (remoteUrl != null && remoteUrl.isNotEmpty) 'remoteUrl': remoteUrl,
      },
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<void> _uploadLpjPackage(SyncRecordEntity record) async {
    final rows = await _database.query(
      'lpj_packages',
      where: 'id = ?',
      whereArgs: [record.entityLocalId],
    );
    if (rows.isEmpty) return;

    final pkg = LpjPackageModel.fromJson(rows.first);
    MultipartFile? pdfMultipart;
    if (pkg.pdfLocalPath != null && File(pkg.pdfLocalPath!).existsSync()) {
      final fileName = pkg.pdfLocalPath!.split(Platform.pathSeparator).last;
      pdfMultipart = await MultipartFile.fromFile(
        pkg.pdfLocalPath!,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap({
      ...pkg.toApiPayload(),
      if (pdfMultipart != null) 'file': pdfMultipart,
    });

    final response = await _dioClient.dio.post(
      '/travel/lpj',
      data: formData,
      options: Options(headers: {'X-Idempotency-Key': record.id}),
    );

    final remoteUrl = response.data['pdfUrl'] as String?;
    await _database.update(
      'lpj_packages',
      {
        'syncStatus': 'SYNCED',
        if (remoteUrl != null && remoteUrl.isNotEmpty) 'pdfRemoteUrl': remoteUrl,
      },
      where: 'id = ?',
      whereArgs: [pkg.id],
    );
  }

  /// Melaporkan satu percobaan capture yang diblokir (mock location /
  /// root device) ke `POST /audit-logs/security-event` - lihat
  /// ReportSecurityEvent (core/security). Tidak ada file yang menyertai
  /// request ini, murni JSON.
  Future<void> _uploadSecurityEvent(SyncRecordEntity record) async {
    final rows = await _database.query(
      'security_events',
      where: 'id = ?',
      whereArgs: [record.entityLocalId],
    );
    if (rows.isEmpty) return;

    final row = rows.first;
    const eventTypeApiValues = {
      'mockLocationBlocked': 'MOCK_LOCATION_BLOCKED',
      'rootDeviceBlocked': 'ROOT_DEVICE_BLOCKED',
    };

    await _dioClient.dio.post(
      '/audit-logs/security-event',
      data: {
        'eventType': eventTypeApiValues[row['eventType']] ??
            'MOCK_LOCATION_BLOCKED',
        'taskId': row['taskId'],
        'latitude': row['latitude'],
        'longitude': row['longitude'],
        'accuracyMeters': row['accuracyMeters'],
        'deviceInfo': row['deviceInfo'],
      },
      options: Options(headers: {'X-Idempotency-Key': record.id}),
    );

    await _database.update(
      'security_events',
      {'syncStatus': 'SYNCED'},
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }
}

