import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/imaging/watermark_compositor.dart';
import 'package:tulap_mobile/core/security/hash_generator.dart';
import 'package:tulap_mobile/features/evidence_gallery/domain/evidence_deletion_policy.dart';
import 'package:tulap_mobile/features/evidence_gallery/domain/usecases/delete_evidence.dart';
import 'package:tulap_mobile/features/geotag_camera/data/datasources/geotag_camera_local_datasource.dart';
import 'package:tulap_mobile/features/geotag_camera/data/models/geotag_photo_model.dart';
import 'package:tulap_mobile/features/sync_queue/data/datasources/sync_local_datasource.dart';
import 'package:tulap_mobile/features/sync_queue/data/models/sync_record_model.dart';
import 'package:tulap_mobile/features/sync_queue/domain/entities/sync_record_entity.dart';

/// Regression test N-08: file ASLI bukti tidak boleh dihapus dari
/// perangkat sebelum ada salinan server yang terverifikasi. Sebelum
/// perbaikan, "Hapus" di galeri menghapus antrean sync (status apa pun),
/// file watermark, file asli, dan metadata - untuk foto yang sudah
/// terkirim, salinan asli satu-satunya ikut hilang.

class _FakeDatabase extends Fake implements Database {}

class _FakeCompositor extends Fake implements WatermarkCompositor {}

/// Mencatat SETIAP operasi tulis supaya test bisa membuktikan tidak ada
/// yang tersentuh saat penghapusan diblokir.
class _RecordingCameraDataSource extends Fake implements GeotagCameraLocalDataSource {
  final Map<String, GeotagPhotoModel> photos = {};
  final List<String> deleteCalls = [];

  @override
  Future<GeotagPhotoModel?> getEvidenceById(String evidenceId) async => photos[evidenceId];

  @override
  Future<void> deletePhoto(String photoId, {bool originalVerifiedOnServer = false}) async {
    deleteCalls.add(photoId);
    photos.remove(photoId);
  }
}

class _RecordingSyncDataSource extends Fake implements SyncLocalDataSource {
  final List<SyncRecordModel> rows = [];
  final List<String> mutations = [];

  @override
  Future<List<SyncRecordModel>> getRecordsByEntityLocalId(String entityLocalId) async =>
      rows.where((r) => r.entityLocalId == entityLocalId).toList();

  @override
  Future<void> deleteRecordsByEntityLocalId(String entityLocalId) async =>
      mutations.add('deleteRecordsByEntityLocalId:$entityLocalId');

  @override
  Future<void> deleteRecord(String id) async => mutations.add('deleteRecord:$id');

  @override
  Future<void> updateRecord(SyncRecordModel record) async =>
      mutations.add('updateRecord:${record.id}');
}

GeotagPhotoModel _evidence({
  String id = 'photo-1',
  String mediaType = 'PHOTO',
  String syncStatus = 'LOCAL_ONLY',
}) => GeotagPhotoModel(
  id: id,
  taskId: 'task-1',
  mediaType: mediaType,
  localFilePath: '/data/tulap_evidence/task-1/photos/$id.jpg',
  originalFilePath: '/data/tulap_evidence/task-1/photos/${id}_raw.jpg',
  latitude: -4.54,
  longitude: 136.87,
  gpsAccuracyMeters: 8,
  plusCode: '6P28+4X',
  integrityHash: 'f' * 64,
  originalHash: 'a' * 64,
  isMockLocationDetected: false,
  isRootedDeviceDetected: false,
  serverTimestamp: DateTime(2026, 10, 13, 9),
  syncStatus: syncStatus,
);

SyncRecordModel _queue(SyncStatus status, {String entityLocalId = 'photo-1'}) => SyncRecordModel(
  id: 'q-${status.name}',
  entityType: SyncEntityType.geotagPhoto,
  entityLocalId: entityLocalId,
  taskId: 'task-1',
  status: status,
  attemptCount: status == SyncStatus.failed ? 5 : 0,
  createdAt: DateTime(2026, 10, 13, 9),
);

void main() {
  late _RecordingCameraDataSource camera;
  late _RecordingSyncDataSource sync;
  late DeleteEvidence deleteEvidence;

  setUp(() {
    camera = _RecordingCameraDataSource();
    sync = _RecordingSyncDataSource();
    deleteEvidence = DeleteEvidence(cameraLocalDataSource: camera, syncLocalDataSource: sync);
  });

  final cases = <({
    String label,
    String mediaType,
    String photoSyncStatus,
    List<SyncStatus> queue,
    EvidenceDeletionBlockReason reason,
    String messageFragment,
  })>[
    (label: 'foto pending (antrean menunggu)', mediaType: 'PHOTO', photoSyncStatus: 'LOCAL_ONLY',
        queue: [SyncStatus.pendingUpload], reason: EvidenceDeletionBlockReason.notYetSent,
        messageFragment: 'belum terkirim'),
    (label: 'foto menunggu internet', mediaType: 'PHOTO', photoSyncStatus: 'LOCAL_ONLY',
        queue: [SyncStatus.waitingForInternet], reason: EvidenceDeletionBlockReason.notYetSent,
        messageFragment: 'belum terkirim'),
    (label: 'foto sedang sync (uploading)', mediaType: 'PHOTO', photoSyncStatus: 'LOCAL_ONLY',
        queue: [SyncStatus.uploading], reason: EvidenceDeletionBlockReason.sending,
        messageFragment: 'sedang dikirim'),
    (label: 'foto gagal sync', mediaType: 'PHOTO', photoSyncStatus: 'LOCAL_ONLY',
        queue: [SyncStatus.failed], reason: EvidenceDeletionBlockReason.sendFailed,
        messageFragment: 'Pusat Sinkronisasi'),
    (label: 'foto SYNCED (watermark terkirim) - BUKAN berarti file asli aman', mediaType: 'PHOTO',
        photoSyncStatus: 'SYNCED', queue: [SyncStatus.synced],
        reason: EvidenceDeletionBlockReason.originalNotOnServer, messageFragment: 'file aslinya belum'),
    (label: 'foto SYNCED tanpa baris antrean tersisa', mediaType: 'PHOTO', photoSyncStatus: 'SYNCED',
        queue: [], reason: EvidenceDeletionBlockReason.originalNotOnServer,
        messageFragment: 'file aslinya belum'),
    (label: 'foto lokal tanpa antrean', mediaType: 'PHOTO', photoSyncStatus: 'LOCAL_ONLY',
        queue: [], reason: EvidenceDeletionBlockReason.notYetSent, messageFragment: 'belum terkirim'),
    (label: 'video SYNCED (hash server tidak tercatat di perangkat)', mediaType: 'VIDEO',
        photoSyncStatus: 'SYNCED', queue: [SyncStatus.synced],
        reason: EvidenceDeletionBlockReason.originalNotOnServer, messageFragment: 'file aslinya belum'),
    (label: 'retry sedang berjalan sementara baris gagal lama masih ada', mediaType: 'PHOTO',
        photoSyncStatus: 'LOCAL_ONLY', queue: [SyncStatus.failed, SyncStatus.uploading],
        reason: EvidenceDeletionBlockReason.sending, messageFragment: 'sedang dikirim'),
  ];

  group('DeleteEvidence memblokir dan tidak menyentuh apa pun', () {
    for (final c in cases) {
      test(c.label, () async {
        camera.photos['photo-1'] = _evidence(mediaType: c.mediaType, syncStatus: c.photoSyncStatus);
        sync.rows.addAll(c.queue.map(_queue));

        final decision = await deleteEvidence.check(evidenceId: 'photo-1');
        expect(decision!.isAllowed, isFalse);
        expect(decision.blockReason, c.reason);
        expect(decision.message, contains(c.messageFragment));
        expect(decision.message, contains('tidak dapat dihapus'));

        final result = await deleteEvidence(evidenceId: 'photo-1');
        final failure = result.fold((f) => f, (_) => null);
        expect(failure, isA<EvidenceDeletionBlockedFailure>());
        expect((failure! as EvidenceDeletionBlockedFailure).decision.blockReason, c.reason);

        expect(camera.deleteCalls, isEmpty, reason: 'file/metadata tidak boleh dihapus');
        expect(camera.photos.containsKey('photo-1'), isTrue);
        expect(sync.mutations, isEmpty, reason: 'antrean sync tidak boleh diubah/dihapus');
        expect(sync.rows.length, c.queue.length);
      });
    }
  });

  test('antrean milik bukti lain tidak memengaruhi keputusan', () async {
    camera.photos['photo-1'] = _evidence(syncStatus: 'SYNCED');
    sync.rows.add(_queue(SyncStatus.uploading, entityLocalId: 'photo-lain'));

    final decision = await deleteEvidence.check(evidenceId: 'photo-1');
    expect(decision!.blockReason, EvidenceDeletionBlockReason.originalNotOnServer);
  });

  test('bukti tidak ditemukan -> NotFoundFailure, tidak ada operasi hapus', () async {
    final result = await deleteEvidence(evidenceId: 'tidak-ada');
    expect(result.fold((f) => f, (_) => null), isA<NotFoundFailure>());
    expect(camera.deleteCalls, isEmpty);
    expect(sync.mutations, isEmpty);
  });

  group('jaring pengaman GeotagCameraLocalDataSource.deletePhoto', () {
    late Directory dir;
    late File original;
    late File watermarked;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('tulap_n08_');
      original = await File('${dir.path}/photo-1_raw.jpg').writeAsBytes([1, 2, 3]);
      watermarked = await File('${dir.path}/photo-1.jpg').writeAsBytes([4, 5, 6]);
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('tanpa konfirmasi file asli terverifikasi -> menolak SEBELUM menyentuh database/file', () async {
      final datasource = GeotagCameraLocalDataSource(
        hashGenerator: HashGenerator(),
        watermarkCompositor: _FakeCompositor(),
        // Fake: akses database apa pun akan melempar UnimplementedError,
        // jadi StateError di bawah membuktikan penolakan terjadi lebih dulu.
        database: _FakeDatabase(),
      );

      await expectLater(datasource.deletePhoto('photo-1'), throwsA(isA<StateError>()));
      expect(await original.exists(), isTrue);
      expect(await watermarked.exists(), isTrue);
    });
  });
}
