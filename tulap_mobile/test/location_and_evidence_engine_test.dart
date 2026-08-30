import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:tulap_mobile/app/di/injection_container.dart';
import 'package:tulap_mobile/core/geo/fast_location_service.dart';
import 'package:tulap_mobile/core/security/hash_generator.dart';
import 'package:tulap_mobile/features/geotag_camera/data/models/geotag_photo_model.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/repositories/geotag_camera_repository.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/capture_geotagged_photo.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/create_evidence.dart';

class _InMemoryTestDatabase extends Fake implements Database {
  final Map<String, Map<String, Object?>> _photos = {};

  @override
  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    final id = values['id'] as String;
    _photos[id] = Map.from(values);
    return 1;
  }

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (where == 'taskId = ?' && whereArgs != null && whereArgs.isNotEmpty) {
      final targetTaskId = whereArgs.first as String;
      return _photos.values
          .where((row) => row['taskId'] == targetTaskId)
          .toList();
    }
    if (where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
      final targetId = whereArgs.first as String;
      final row = _photos[targetId];
      return row != null ? [row] : [];
    }
    return _photos.values.toList();
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (where == 'id = ?' && whereArgs != null && whereArgs.isNotEmpty) {
      final targetId = whereArgs.first as String;
      _photos.remove(targetId);
      return 1;
    }
    final count = _photos.length;
    _photos.clear();
    return count;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async => [{'count': _photos.length}];

  @override
  Batch batch() => _FakeTestBatch();
}

class _FakeTestBatch extends Fake implements Batch {
  @override
  void insert(
    String table,
    Map<String, Object?> values, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) {}

  @override
  Future<List<Object?>> commit({
    bool? exclusive,
    bool? noResult,
    bool? continueOnError,
  }) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Phase 2: Fast Location Engine & Quality Classification Tests', () {
    test('Location Quality: Classifies accuracy into forensic tiers', () {
      expect(LocationQuality.fromAccuracy(5.0), equals(LocationQuality.excellent));
      expect(LocationQuality.fromAccuracy(10.0), equals(LocationQuality.excellent));
      expect(LocationQuality.fromAccuracy(18.5), equals(LocationQuality.good));
      expect(LocationQuality.fromAccuracy(25.0), equals(LocationQuality.good));
      expect(LocationQuality.fromAccuracy(35.0), equals(LocationQuality.acceptable));
      expect(LocationQuality.fromAccuracy(50.0), equals(LocationQuality.acceptable));
      expect(LocationQuality.fromAccuracy(74.0), equals(LocationQuality.poor));
      expect(LocationQuality.fromAccuracy(null), equals(LocationQuality.poor));
    });

    test('Location Labels: Formats clear Indonesian status badge text', () {
      expect(
        LocationQuality.excellent.labelIndonesian(7.2),
        equals('✓ Lokasi sangat akurat · ±7 m'),
      );
      expect(
        LocationQuality.good.labelIndonesian(18.0),
        equals('✓ Lokasi akurat · ±18 m'),
      );
      expect(
        LocationQuality.acceptable.labelIndonesian(37.0),
        equals('● Lokasi tersedia · ±37 m'),
      );
      expect(
        LocationQuality.poor.labelIndonesian(82.0),
        equals('⚠ Akurasi rendah · ±82 m'),
      );
    });

    test('Location Snapshot: Converts FastLocationData to immutable snapshot', () {
      final locData = FastLocationData(
        tier: LocationTier.verified,
        latitude: -4.5468,
        longitude: 136.8837,
        accuracy: 8.5,
        altitude: 45.2,
        heading: 180.0,
        address: 'Jl. Cenderawasih, Timika',
        timestamp: DateTime(2026, 8, 26, 12, 0),
        isMocked: false,
      );

      final snapshot = locData.toSnapshot();
      expect(snapshot, isNotNull);
      expect(snapshot!.latitude, equals(-4.5468));
      expect(snapshot.longitude, equals(136.8837));
      expect(snapshot.accuracy, equals(8.5));
      expect(snapshot.altitude, equals(45.2));
      expect(snapshot.heading, equals(180.0));
      expect(snapshot.address, equals('Jl. Cenderawasih, Timika'));
      expect(snapshot.isMock, isFalse);
      expect(snapshot.quality, equals(LocationQuality.excellent));
    });
  });

  group('Phase 2: Streaming Chunked SHA-256 Hashing Tests', () {
    late Directory tempDir;
    late HashGenerator hashGenerator;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tulap_hash_test_');
      hashGenerator = HashGenerator();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Streaming SHA-256: Computes exact hash matching independent digest', () async {
      final testFile = File(p.join(tempDir.path, 'sample_video.mp4'));
      final sampleBytes = Uint8List.fromList(
        List.generate(1024 * 100, (i) => i % 256), // 100 KB payload
      );
      await testFile.writeAsBytes(sampleBytes);

      final computedHash = await hashGenerator.generateSha256(testFile.path);
      final expectedHash = sha256.convert(sampleBytes).toString();

      expect(computedHash, equals(expectedHash));
      expect(computedHash.length, equals(64));
    });

    test('Missing File: Throws FileSystemException when file does not exist', () async {
      expect(
        () => hashGenerator.generateSha256(p.join(tempDir.path, 'non_existent.jpg')),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('Phase 2: Evidence Database & v8 Model Serialization Tests', () {
    late _InMemoryTestDatabase db;

    setUp(() {
      db = _InMemoryTestDatabase();
    });

    test('Insert and Query Photo Evidence: Preserves all metadata & activity binding', () async {
      final photo = GeotagPhotoModel(
        id: 'photo-uuid-001',
        taskId: 'activity-101',
        userId: 'user-leonardo',
        mediaType: 'PHOTO',
        localFilePath: '/storage/tulap_evidence/activity-101/photos/photo-uuid-001.jpg',
        originalFilePath: '/storage/tulap_evidence/activity-101/photos/photo-uuid-001_raw.jpg',
        latitude: -4.546812,
        longitude: 136.883745,
        gpsAccuracyMeters: 7.5,
        altitude: 35.0,
        heading: 90.0,
        plusCode: '6P28MMMM+XX',
        serverTimestamp: DateTime(2026, 8, 26, 14, 0),
        deviceTimestamp: DateTime(2026, 8, 26, 14, 0),
        durationSeconds: 0,
        integrityHash: 'a' * 64,
        originalHash: 'b' * 64,
        finalHash: 'a' * 64,
        shortEvidenceId: 'TL-20260826-0001',
        verificationStatus: EvidenceVerificationStatus.recorded,
        syncStatus: 'LOCAL_ONLY',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
        address: 'Jl. Merdeka, Mimika',
        caption: 'Inspeksi Lapangan BPKAD',
      );

      await db.insert('geotag_photos', photo.toJson());

      final results = await db.query('geotag_photos', where: 'taskId = ?', whereArgs: ['activity-101']);
      expect(results.length, equals(1));

      final retrieved = GeotagPhotoModel.fromJson(results.first);
      expect(retrieved.id, equals('photo-uuid-001'));
      expect(retrieved.taskId, equals('activity-101'));
      expect(retrieved.userId, equals('user-leonardo'));
      expect(retrieved.mediaType, equals('PHOTO'));
      expect(retrieved.isPhoto, isTrue);
      expect(retrieved.isVideo, isFalse);
      expect(retrieved.latitude, equals(-4.546812));
      expect(retrieved.longitude, equals(136.883745));
      expect(retrieved.gpsAccuracyMeters, equals(7.5));
      expect(retrieved.syncStatus, equals('LOCAL_ONLY'));
      expect(retrieved.shortEvidenceId, equals('TL-20260826-0001'));
    });

    test('Insert and Query Video Evidence: Preserves video duration & mediaType', () async {
      final video = GeotagPhotoModel(
        id: 'video-uuid-002',
        taskId: 'activity-101',
        userId: 'user-leonardo',
        mediaType: 'VIDEO',
        localFilePath: '/storage/tulap_evidence/activity-101/videos/video-uuid-002.mp4',
        originalFilePath: '/storage/tulap_evidence/activity-101/videos/video-uuid-002.mp4',
        latitude: -4.546812,
        longitude: 136.883745,
        gpsAccuracyMeters: 11.2,
        altitude: 35.0,
        heading: 120.0,
        plusCode: '6P28MMMM+XX',
        serverTimestamp: DateTime(2026, 8, 26, 14, 15),
        deviceTimestamp: DateTime(2026, 8, 26, 14, 15),
        durationSeconds: 28,
        integrityHash: 'c' * 64,
        originalHash: 'c' * 64,
        finalHash: 'c' * 64,
        shortEvidenceId: 'TL-20260826-0002',
        verificationStatus: EvidenceVerificationStatus.recorded,
        syncStatus: 'LOCAL_ONLY',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
        address: 'Jl. Merdeka, Mimika',
        caption: 'Dokumentasi Video Lapangan',
      );

      await db.insert('geotag_photos', video.toJson());

      final results = await db.query('geotag_photos', where: 'id = ?', whereArgs: ['video-uuid-002']);
      expect(results.length, equals(1));

      final retrieved = GeotagPhotoModel.fromJson(results.first);
      expect(retrieved.mediaType, equals('VIDEO'));
      expect(retrieved.isVideo, isTrue);
      expect(retrieved.isPhoto, isFalse);
      expect(retrieved.durationSeconds, equals(28));
    });

    test('Activity Isolation: Evidence in Activity A is not mixed with Activity B', () async {
      final itemA = GeotagPhotoModel(
        id: 'photo-A',
        taskId: 'task-A',
        mediaType: 'PHOTO',
        localFilePath: 'path_a.jpg',
        latitude: -4.5,
        longitude: 136.8,
        gpsAccuracyMeters: 10.0,
        plusCode: '6P28MMMM+XX',
        serverTimestamp: DateTime(2026, 8, 26),
        integrityHash: 'hashA',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
      );

      final itemB = GeotagPhotoModel(
        id: 'photo-B',
        taskId: 'task-B',
        mediaType: 'PHOTO',
        localFilePath: 'path_b.jpg',
        latitude: -4.5,
        longitude: 136.8,
        gpsAccuracyMeters: 10.0,
        plusCode: '6P28MMMM+XX',
        serverTimestamp: DateTime(2026, 8, 26),
        integrityHash: 'hashB',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
      );

      await db.insert('geotag_photos', itemA.toJson());
      await db.insert('geotag_photos', itemB.toJson());

      final rowsA = await db.query('geotag_photos', where: 'taskId = ?', whereArgs: ['task-A']);
      final rowsB = await db.query('geotag_photos', where: 'taskId = ?', whereArgs: ['task-B']);

      expect(rowsA.length, equals(1));
      expect(rowsA.first['id'], equals('photo-A'));
      expect(rowsB.length, equals(1));
      expect(rowsB.first['id'], equals('photo-B'));
    });
  });

  group('Phase 2: GetIt Service Locator & Dependency Resolution Tests', () {
    test('GetIt Resolution: All Phase 2 services and use cases resolve cleanly', () async {
      final memoryDb = _InMemoryTestDatabase();
      await initDependencies(database: memoryDb);

      expect(sl.isRegistered<FastLocationService>(), isTrue);
      expect(sl.isRegistered<HashGenerator>(), isTrue);
      expect(sl.isRegistered<GeotagCameraRepository>(), isTrue);
      expect(sl.isRegistered<CaptureGeotaggedPhoto>(), isTrue);
      expect(sl.isRegistered<CreateEvidence>(), isTrue);

      final createEvidence = sl<CreateEvidence>();
      expect(createEvidence, isA<CreateEvidence>());

      final hashGen = sl<HashGenerator>();
      expect(hashGen, isA<HashGenerator>());

      final fastLoc = sl<FastLocationService>();
      expect(fastLoc, isA<FastLocationService>());
    });
  });
}
