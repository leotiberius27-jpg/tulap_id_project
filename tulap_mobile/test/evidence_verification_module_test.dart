import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tulap_mobile/core/security/hash_generator.dart';
import 'package:tulap_mobile/features/evidence_verification/domain/entities/evidence_verification_result.dart';
import 'package:tulap_mobile/features/evidence_verification/domain/usecases/verify_evidence_integrity.dart';
import 'package:tulap_mobile/features/evidence_verification/presentation/pages/evidence_detail_page.dart';
import 'package:tulap_mobile/features/evidence_verification/presentation/pages/evidence_verification_page.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';

class FakeDatabase implements Database {
  final Map<String, dynamic> updatedData = {};

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    updatedData.addAll(values);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HashGenerator hashGenerator;
  late FakeDatabase fakeDatabase;
  late VerifyEvidenceIntegrity verifyEvidenceIntegrity;
  late Directory tempDir;

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    tempDir = await Directory.systemTemp.createTemp('tulap_test_evidence_');
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() {
    hashGenerator = HashGenerator();
    fakeDatabase = FakeDatabase();
    verifyEvidenceIntegrity = VerifyEvidenceIntegrity(
      hashGenerator: hashGenerator,
      database: fakeDatabase,
    );

    if (GetIt.I.isRegistered<VerifyEvidenceIntegrity>()) {
      GetIt.I.unregister<VerifyEvidenceIntegrity>();
    }
    GetIt.I.registerLazySingleton<VerifyEvidenceIntegrity>(
      () => verifyEvidenceIntegrity,
    );
  });

  group('Evidence Verification Engine Tests', () {
    test('PASS: Valid file SHA-256 matches stored hash', () async {
      final testFile = File('${tempDir.path}/valid_photo.jpg');
      await testFile.writeAsString('TULAP_OFFICIAL_EVIDENCE_VALID_PAYLOAD_2026');
      final validHash = await hashGenerator.generateSha256(testFile.path);

      final photo = GeotagPhotoEntity(
        id: 'photo-uuid-1',
        taskId: 'TL-202608-0001',
        localFilePath: testFile.path,
        latitude: -4.540346,
        longitude: 136.876482,
        gpsAccuracyMeters: 12.0,
        plusCode: '6P28+3Q Timika',
        serverTimestamp: DateTime(2026, 8, 26, 11, 13, 0),
        integrityHash: validHash,
        finalHash: validHash,
        shortEvidenceId: 'TL-20260826-9760',
        verificationStatus: EvidenceVerificationStatus.synced,
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
        address: 'Jl. Cenderawasih, Mimika Baru',
        caption: 'Monitoring Lapangan',
      );

      final result = await verifyEvidenceIntegrity(
        photo: photo,
        isOnline: true,
      );

      expect(result.isFinalHashValid, isTrue);
      expect(result.computedFinalHash, equals(validHash));
      expect(result.hasValidLocation, isTrue);
      expect(result.isMockLocationDetected, isFalse);
      expect(result.isRootedDeviceDetected, isFalse);
      expect(result.overallStatus, equals(EvidenceVerificationStatus.verified));
      expect(result.isFullyVerified, isTrue);
    });

    test('FAIL: Modified / Tampered file triggers hash mismatch and INTEGRITY_FAILED', () async {
      final testFile = File('${tempDir.path}/tampered_photo.jpg');
      await testFile.writeAsString('ORIGINAL_CONTENT_BEFORE_TAMPER');
      final originalRecordedHash = await hashGenerator.generateSha256(testFile.path);

      // Silently alter file content
      await testFile.writeAsString('TAMPERED_MALICIOUS_MODIFIED_CONTENT');

      final photo = GeotagPhotoEntity(
        id: 'photo-uuid-2',
        taskId: 'TL-202608-0002',
        localFilePath: testFile.path,
        latitude: -4.540346,
        longitude: 136.876482,
        gpsAccuracyMeters: 10.0,
        plusCode: '6P28+3Q Timika',
        serverTimestamp: DateTime(2026, 8, 26, 11, 13, 0),
        integrityHash: originalRecordedHash,
        finalHash: originalRecordedHash,
        shortEvidenceId: 'TL-20260826-9761',
        verificationStatus: EvidenceVerificationStatus.synced,
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
      );

      final result = await verifyEvidenceIntegrity(
        photo: photo,
        isOnline: true,
      );

      expect(result.isFinalHashValid, isFalse);
      expect(result.computedFinalHash, isNot(equals(originalRecordedHash)));
      expect(result.overallStatus, equals(EvidenceVerificationStatus.integrityFailed));
      expect(result.isIntegrityFailed, isTrue);
    });

    test('FAIL: Mock Location (Fake GPS) prevents verified status', () async {
      final testFile = File('${tempDir.path}/mock_gps_photo.jpg');
      await testFile.writeAsString('VALID_IMAGE_DATA_WITH_FAKE_GPS');
      final hash = await hashGenerator.generateSha256(testFile.path);

      final photo = GeotagPhotoEntity(
        id: 'photo-uuid-3',
        taskId: 'TL-202608-0003',
        localFilePath: testFile.path,
        latitude: -4.540346,
        longitude: 136.876482,
        gpsAccuracyMeters: 8.0,
        plusCode: '6P28+3Q Timika',
        serverTimestamp: DateTime.now(),
        integrityHash: hash,
        finalHash: hash,
        shortEvidenceId: 'TL-20260826-9762',
        verificationStatus: EvidenceVerificationStatus.synced,
        isMockLocationDetected: true, // Fake GPS detected!
        isRootedDeviceDetected: false,
      );

      final result = await verifyEvidenceIntegrity(
        photo: photo,
        isOnline: true,
      );

      expect(result.isMockLocationDetected, isTrue);
      expect(result.overallStatus, equals(EvidenceVerificationStatus.integrityFailed));
      expect(result.isFullyVerified, isFalse);
    });

    test('OFFLINE: Offline evidence marks RECORDED with local verification passed', () async {
      final testFile = File('${tempDir.path}/offline_photo.jpg');
      await testFile.writeAsString('OFFLINE_CAPTURED_EVIDENCE');
      final hash = await hashGenerator.generateSha256(testFile.path);

      final photo = GeotagPhotoEntity(
        id: 'photo-uuid-4',
        taskId: 'TL-202608-0004',
        localFilePath: testFile.path,
        latitude: -4.540346,
        longitude: 136.876482,
        gpsAccuracyMeters: 14.0,
        plusCode: '6P28+3Q Timika',
        serverTimestamp: DateTime.now(),
        integrityHash: hash,
        finalHash: hash,
        shortEvidenceId: 'TL-20260826-9763',
        verificationStatus: EvidenceVerificationStatus.recorded,
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
      );

      final result = await verifyEvidenceIntegrity(
        photo: photo,
        isOnline: false,
      );

      expect(result.isFinalHashValid, isTrue);
      expect(result.isSynced, isFalse);
      expect(result.overallStatus, equals(EvidenceVerificationStatus.recorded));
    });

    test('REVIEW_REQUIRED: GPS Accuracy > 50m requires review', () async {
      final testFile = File('${tempDir.path}/weak_gps_photo.jpg');
      await testFile.writeAsString('ACCURACY_WEAK_DATA');
      final hash = await hashGenerator.generateSha256(testFile.path);

      final photo = GeotagPhotoEntity(
        id: 'photo-uuid-5',
        taskId: 'TL-202608-0005',
        localFilePath: testFile.path,
        latitude: -4.540346,
        longitude: 136.876482,
        gpsAccuracyMeters: 85.0, // Inaccurate GPS
        plusCode: '6P28+3Q Timika',
        serverTimestamp: DateTime.now(),
        integrityHash: hash,
        finalHash: hash,
        shortEvidenceId: 'TL-20260826-9764',
        verificationStatus: EvidenceVerificationStatus.synced,
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
      );

      final result = await verifyEvidenceIntegrity(
        photo: photo,
        isOnline: true,
      );

      expect(result.isFinalHashValid, isTrue);
      expect(result.overallStatus, equals(EvidenceVerificationStatus.reviewRequired));
      expect(result.isReviewRequired, isTrue);
    });
  });

  group('Evidence Verification UI Tests', () {
    testWidgets('EvidenceDetailPage renders photo info and Verifikasi Bukti button', (tester) async {
      final photo = GeotagPhotoEntity(
        id: 'photo-ui-1',
        taskId: 'TL-202608-0010',
        localFilePath: 'dummy_nonexistent_for_ui_test.jpg',
        latitude: -4.540346,
        longitude: 136.876482,
        gpsAccuracyMeters: 15.0,
        plusCode: '6P28+3Q Timika',
        serverTimestamp: DateTime(2026, 8, 26, 11, 13, 0),
        integrityHash: 'mock-hash-123',
        finalHash: 'mock-hash-123',
        shortEvidenceId: 'TL-20260826-9760',
        verificationStatus: EvidenceVerificationStatus.recorded,
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
        address: 'Jl. Cenderawasih, Mimika Baru',
        caption: 'Monitoring Kendaraan Dinas',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EvidenceDetailPage(photo: photo),
        ),
      );
      await tester.pump();

      expect(find.text('TL-20260826-9760'), findsOneWidget);
      expect(find.text('Monitoring Kendaraan Dinas'), findsOneWidget);
      expect(find.text('Jl. Cenderawasih, Mimika Baru'), findsOneWidget);
      expect(find.text('±15 m'), findsOneWidget);
      expect(find.text('Verifikasi Integritas Bukti'), findsOneWidget);
    });

    testWidgets('EvidenceVerificationPage renders status and checklist tiles', (tester) async {
      final photo = GeotagPhotoEntity(
        id: 'photo-ui-2',
        taskId: 'TL-202608-0011',
        localFilePath: 'dummy_verify_path.jpg',
        latitude: -4.540346,
        longitude: 136.876482,
        gpsAccuracyMeters: 15.0,
        plusCode: '6P28+3Q Timika',
        serverTimestamp: DateTime(2026, 8, 26, 11, 13, 0),
        integrityHash: 'mock-valid-hash',
        finalHash: 'mock-valid-hash',
        shortEvidenceId: 'TL-20260826-9760',
        verificationStatus: EvidenceVerificationStatus.synced,
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
        address: 'Jl. Cenderawasih, Mimika Baru',
        caption: 'Monitoring Tugas Lapangan',
      );

      final result = EvidenceVerificationResult(
        photoId: 'photo-ui-2',
        taskId: 'TL-202608-0011',
        shortEvidenceId: 'TL-20260826-9760',
        localFilePath: 'dummy_verify_path.jpg',
        isFinalHashValid: true,
        computedFinalHash: 'mock-valid-hash',
        storedFinalHash: 'mock-valid-hash',
        hasValidLocation: true,
        latitude: -4.540346,
        longitude: 136.876482,
        gpsAccuracyMeters: 15.0,
        address: 'Jl. Cenderawasih, Mimika Baru',
        plusCode: '6P28+3Q Timika',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
        isActivityBound: true,
        taskTitle: 'Monitoring Tugas Lapangan',
        officerName: 'Leonardo',
        agencyName: 'BPKAD Kabupaten Mimika',
        serverTimestamp: DateTime(2026, 8, 26, 11, 13, 0),
        isSynced: true,
        overallStatus: EvidenceVerificationStatus.verified,
        verifiedAt: DateTime(2026, 8, 26, 11, 13, 5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: EvidenceVerificationPage(
            photo: photo,
            initialResult: result,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('HASIL PEMERIKSAAN INTEGRITAS'), findsOneWidget);
      expect(find.text('Integritas File Foto (SHA-256)'), findsOneWidget);
      expect(find.text('Metadata Lokasi Geografis'), findsOneWidget);
      expect(find.text('Deteksi Lokasi Palsu (Fake GPS)'), findsOneWidget);
      expect(find.text('Waktu & Provensi Bukti'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      expect(find.text('Lihat Detail Teknis & Kriptografi'), findsOneWidget);
    });
  });
}
