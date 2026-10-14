import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tulap_mobile/core/network/dio_client.dart';
import 'package:tulap_mobile/core/network/network_info.dart';
import 'package:tulap_mobile/features/sync_queue/data/datasources/sync_local_datasource.dart';
import 'package:tulap_mobile/features/sync_queue/data/datasources/sync_remote_datasource.dart';
import 'package:tulap_mobile/features/sync_queue/data/models/sync_record_model.dart';
import 'package:tulap_mobile/features/sync_queue/data/repositories/sync_queue_repository_impl.dart';
import 'package:tulap_mobile/features/sync_queue/domain/entities/sync_record_entity.dart';
import 'package:tulap_mobile/features/sync_queue/domain/usecases/process_sync_queue.dart';

/// Regression test P0-05: item outbox yang tertinggal berstatus
/// `uploading` karena aplikasi mati di tengah upload. Sebelum perbaikan,
/// item tsb tidak pernah diproses ulang otomatis dan tidak punya tombol
/// "Coba Lagi" - bukti tidak pernah sampai ke server.

class _FakeDatabase extends Fake implements Database {}

/// Tabel `sync_queue` in-memory. Dibagi antar instance repository untuk
/// mensimulasikan SQLite yang bertahan melewati restart aplikasi.
class _InMemorySyncLocalDataSource extends SyncLocalDataSource {
  final Map<String, SyncRecordModel> rows;

  _InMemorySyncLocalDataSource(this.rows) : super(_FakeDatabase());

  @override
  Future<List<SyncRecordModel>> getAll() async => rows.values.toList();

  @override
  Future<SyncRecordModel?> getById(String id) async => rows[id];

  @override
  Future<void> updateRecord(SyncRecordModel record) async {
    rows[record.id] = record;
  }
}

class _ControllableRemote extends SyncRemoteDataSource {
  int uploadCalls = 0;

  /// Jika diisi, upload menunggu completer ini (simulasi upload yang
  /// sedang berjalan / tidak pernah selesai karena aplikasi mati).
  Completer<void>? gate;
  Object? errorToThrow;

  _ControllableRemote()
    : super(
        dioClient: DioClient(baseUrl: 'http://localhost'),
        database: _FakeDatabase(),
      );

  @override
  Future<void> uploadRecord(SyncRecordEntity record) async {
    uploadCalls++;
    if (gate != null) await gate!.future;
    if (errorToThrow != null) throw errorToThrow!;
  }
}

class _FakeNetworkInfo implements NetworkInfo {
  bool online = true;

  @override
  Future<bool> get isConnected async => online;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

SyncRecordModel _record(
  String id, {
  SyncStatus status = SyncStatus.pendingUpload,
  int attemptCount = 0,
}) => SyncRecordModel(
  id: id,
  entityType: SyncEntityType.geotagPhoto,
  entityLocalId: 'photo_$id',
  taskId: 'task_1',
  status: status,
  attemptCount: attemptCount,
  createdAt: DateTime(2026, 10, 13, 8),
);

void main() {
  late Map<String, SyncRecordModel> sqlite;
  late _FakeNetworkInfo network;

  SyncQueueRepositoryImpl newAppProcess(_ControllableRemote remote) =>
      SyncQueueRepositoryImpl(
        localDataSource: _InMemorySyncLocalDataSource(sqlite),
        remoteDataSource: remote,
        networkInfo: network,
      );

  setUp(() {
    sqlite = {};
    network = _FakeNetworkInfo();
  });

  test('aplikasi mati di tengah upload -> setelah dibuka ulang, satu siklus sync mengirimnya', () async {
    sqlite['r1'] = _record('r1');

    // Proses aplikasi #1: upload dimulai lalu "aplikasi mati" - future
    // upload tidak pernah selesai, record tertinggal `uploading`.
    final remoteBeforeKill = _ControllableRemote()..gate = Completer<void>();
    unawaited(newAppProcess(remoteBeforeKill).processRecord('r1'));
    await pumpEventQueue();
    expect(sqlite['r1']!.status, SyncStatus.uploading);

    // Proses aplikasi #2 (instance baru, SQLite yang sama).
    final remoteAfterRestart = _ControllableRemote();
    final repo = newAppProcess(remoteAfterRestart);
    final result = await ProcessSyncQueue(repository: repo, networkInfo: network)();

    expect(sqlite['r1']!.status, SyncStatus.synced);
    expect(remoteAfterRestart.uploadCalls, 1);
    expect(result.totalSynced, 1);
    // Percobaan yang terputus ikut dihitung (1) + percobaan yang berhasil (1).
    expect(sqlite['r1']!.attemptCount, 2);
  });

  test('pemulihan saat offline -> "Menunggu internet", bukan "Mengirim" palsu; tidak upload', () async {
    sqlite['r1'] = _record('r1', status: SyncStatus.uploading, attemptCount: 1);
    network.online = false;
    final remote = _ControllableRemote();

    await ProcessSyncQueue(repository: newAppProcess(remote), networkInfo: network)();

    final r1 = sqlite['r1']!;
    expect(r1.status, SyncStatus.waitingForInternet);
    expect(r1.attemptCount, 2);
    expect(r1.lastErrorMessage, contains('terputus'));
    expect(r1.lastAttemptAt, isNotNull);
    expect(remote.uploadCalls, 0);
  });

  test('terputus berulang sampai batas percobaan -> "Gagal" dengan arahan "Coba Lagi", lalu retry manual berhasil', () async {
    sqlite['r1'] = _record(
      'r1',
      status: SyncStatus.uploading,
      attemptCount: SyncRecordEntity.maxAutoRetryAttempts - 1,
    );
    final remote = _ControllableRemote();
    final repo = newAppProcess(remote);

    await ProcessSyncQueue(repository: repo, networkInfo: network)();

    expect(sqlite['r1']!.status, SyncStatus.failed);
    expect(sqlite['r1']!.lastErrorMessage, contains('Coba Lagi'));
    expect(remote.uploadCalls, 0, reason: 'tidak boleh berputar otomatis tanpa akhir');

    await repo.retryRecord('r1');
    expect(sqlite['r1']!.status, SyncStatus.synced);
    expect(remote.uploadCalls, 1);
  });

  test('upload yang BENAR-BENAR sedang berjalan tidak disentuh dan tidak dikirim dua kali', () async {
    sqlite['r1'] = _record('r1');
    final remote = _ControllableRemote()..gate = Completer<void>();
    final repo = newAppProcess(remote);

    final inFlight = repo.processRecord('r1');
    await pumpEventQueue();
    expect(sqlite['r1']!.status, SyncStatus.uploading);

    final recovered = await repo.recoverInterruptedUploads();
    expect(recovered.getOrElse(() => -1), 0);
    expect(sqlite['r1']!.status, SyncStatus.uploading);
    expect(sqlite['r1']!.attemptCount, 0);

    // Sync latar belakang + "Coba Lagi" manual berbarengan.
    await repo.processRecord('r1');
    await repo.retryRecord('r1');
    expect(sqlite['r1']!.status, SyncStatus.uploading,
        reason: 'retry tidak boleh menimpa status upload yang sedang berjalan');

    remote.gate!.complete();
    await inFlight;

    expect(remote.uploadCalls, 1);
    expect(sqlite['r1']!.status, SyncStatus.synced);
  });

  test('pemulihan hanya menyentuh status `uploading`', () async {
    sqlite
      ..['pending'] = _record('pending', attemptCount: 1)
      ..['waiting'] = _record('waiting', status: SyncStatus.waitingForInternet, attemptCount: 2)
      ..['failed'] = _record('failed', status: SyncStatus.failed, attemptCount: 5)
      ..['synced'] = _record('synced', status: SyncStatus.synced, attemptCount: 1)
      ..['stuck'] = _record('stuck', status: SyncStatus.uploading, attemptCount: 0);
    final before = Map.of(sqlite);

    final recovered = await newAppProcess(_ControllableRemote()).recoverInterruptedUploads();

    expect(recovered.getOrElse(() => -1), 1);
    for (final id in ['pending', 'waiting', 'failed', 'synced']) {
      expect(sqlite[id]!.status, before[id]!.status, reason: id);
      expect(sqlite[id]!.attemptCount, before[id]!.attemptCount, reason: id);
    }
    expect(sqlite['stuck']!.status, SyncStatus.waitingForInternet);
  });

  group('perilaku existing tetap sama', () {
    test('401 (sesi habis) tetap langsung `failed` tanpa retry otomatis', () async {
      sqlite['r1'] = _record('r1');
      final options = RequestOptions(path: '/evidence/photo');
      final remote = _ControllableRemote()
        ..errorToThrow = DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 401),
        );

      await newAppProcess(remote).processRecord('r1');

      expect(sqlite['r1']!.status, SyncStatus.failed);
      expect(sqlite['r1']!.lastErrorMessage, contains('login ulang'));
    });

    test('gagal jaringan sesaat -> `waitingForInternet` untuk retry otomatis', () async {
      sqlite['r1'] = _record('r1');
      final remote = _ControllableRemote()
        ..errorToThrow = DioException(
          requestOptions: RequestOptions(path: '/evidence/photo'),
          type: DioExceptionType.connectionError,
        );

      await newAppProcess(remote).processRecord('r1');

      expect(sqlite['r1']!.status, SyncStatus.waitingForInternet);
      expect(sqlite['r1']!.attemptCount, 1);
    });

    test('record yang sedang diproses dilepas lagi setelah gagal (bisa diproses ulang)', () async {
      sqlite['r1'] = _record('r1');
      final remote = _ControllableRemote()..errorToThrow = Exception('boom');
      final repo = newAppProcess(remote);

      await repo.processRecord('r1');
      remote.errorToThrow = null;
      await repo.processRecord('r1');

      expect(remote.uploadCalls, 2);
      expect(sqlite['r1']!.status, SyncStatus.synced);
    });
  });
}
