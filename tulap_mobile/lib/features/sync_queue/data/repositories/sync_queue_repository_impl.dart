import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/sync_record_entity.dart';
import '../../domain/repositories/sync_queue_repository.dart';
import '../datasources/sync_local_datasource.dart';
import '../datasources/sync_remote_datasource.dart';
import '../models/sync_record_model.dart';

class SyncQueueFailure extends Failure {
  const SyncQueueFailure([
    super.message = 'Gagal memproses antrian sinkronisasi.',
  ]);
}

/// SyncQueueRepositoryImpl
/// ----------------------------------------------------------------------
/// Menggabungkan local datasource (outbox), remote datasource (upload),
/// dan NetworkInfo untuk menegakkan alur status sesuai Bagian 10:
///   Tersimpan -> Menunggu Internet -> Mengirim -> Terkirim / Gagal
/// ----------------------------------------------------------------------
class SyncQueueRepositoryImpl implements SyncQueueRepository {
  final SyncLocalDataSource _localDataSource;
  final SyncRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  /// ID record yang SEDANG diproses `processRecord` di proses aplikasi
  /// ini. Status `uploading` di SQLite bertahan walau aplikasi mati di
  /// tengah upload - set in-memory inilah yang membedakan "benar-benar
  /// sedang mengirim" dari "tertinggal karena aplikasi tertutup"
  /// (lihat recoverInterruptedUploads). Repository ini lazy singleton
  /// di DI, jadi set ini berlaku untuk seluruh aplikasi.
  final Set<String> _inFlightRecordIds = <String>{};

  SyncQueueRepositoryImpl({
    required SyncLocalDataSource localDataSource,
    required SyncRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _networkInfo = networkInfo;

  @override
  Future<Either<Failure, SyncRecordEntity>> enqueue({
    required SyncEntityType entityType,
    required String entityLocalId,
    required String taskId,
  }) async {
    try {
      final record = await _localDataSource.insertRecord(
        entityType: entityType,
        entityLocalId: entityLocalId,
        taskId: taskId,
      );
      return Right(record);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, List<SyncRecordEntity>>> getAllRecords() async {
    try {
      final records = await _localDataSource.getAll();
      return Right(records);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, SyncRecordEntity>> processRecord(
    String recordId,
  ) async {
    final record = await _localDataSource.getById(recordId);
    if (record == null) {
      return const Left(SyncQueueFailure('Data antrian tidak ditemukan.'));
    }

    // Record yang sama sudah sedang dikirim (mis. sync latar belakang
    // dan tombol "Coba Lagi" berbarengan) - jangan upload paralel kedua
    // kalinya.
    if (!_inFlightRecordIds.add(recordId)) {
      return Right(record);
    }

    try {
      return await _processClaimedRecord(record);
    } finally {
      _inFlightRecordIds.remove(recordId);
    }
  }

  Future<Either<Failure, SyncRecordEntity>> _processClaimedRecord(
    SyncRecordEntity record,
  ) async {
    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      final waiting = SyncRecordModel.fromEntity(
        record.copyWith(status: SyncStatus.waitingForInternet),
      );
      await _localDataSource.updateRecord(waiting);
      return Right(waiting);
    }

    // Tandai "Mengirim" dulu sebelum benar-benar upload, supaya UI
    // Sync Center bisa menampilkan status real-time jika data di-poll
    // selagi proses berjalan.
    final uploading = SyncRecordModel.fromEntity(
      record.copyWith(status: SyncStatus.uploading),
    );
    await _localDataSource.updateRecord(uploading);

    try {
      await _remoteDataSource.uploadRecord(record);

      final synced = SyncRecordModel.fromEntity(
        record.copyWith(
          status: SyncStatus.synced,
          attemptCount: record.attemptCount + 1,
          lastAttemptAt: DateTime.now(),
          lastErrorMessage: null,
        ),
      );
      await _localDataSource.updateRecord(synced);
      return Right(synced);
    } on DioException catch (e) {
      final errorMessage = _mapDioErrorToUserMessage(e);
      // Sesi login benar-benar tidak valid (access token kedaluwarsa DAN
      // refresh token-nya juga ditolak server - DioClient sudah mencoba
      // refresh otomatis sebelum melempar error ini, lihat DioClient
      // onError). Retry otomatis sia-sia di sini: tanpa login ulang,
      // percobaan ke-2 sampai ke-5 pasti gagal dengan alasan yang sama -
      // langsung tandai `failed` supaya user tahu harus login ulang,
      // bukan menunggu 5 percobaan otomatis yang mustahil berhasil.
      final result = await _recordAttemptFailure(
        record,
        errorMessage,
        forceFailedImmediately: e.response?.statusCode == 401,
      );
      return Right(result);
    } catch (e) {
      final result = await _recordAttemptFailure(
        record,
        'Data belum berhasil dikirim.',
      );
      return Right(result);
    }
  }

  /// _recordAttemptFailure
  /// ----------------------------------------------------------------------
  /// SEBELUM perbaikan ini, kegagalan APA PUN (termasuk kegagalan
  /// sesaat/transien - mis. file lokal belum selesai ditulis OS tepat
  /// saat percobaan sinkronisasi otomatis pertama terjadi, dikonfirmasi
  /// nyata lewat testing langsung di perangkat fisik) langsung menandai
  /// item `failed` pada percobaan PERTAMA, memaksa user membuka Sync
  /// Center dan menekan "Coba Lagi" secara manual setiap kali - padahal
  /// SyncRecordEntity.maxAutoRetryAttempts (5) sudah ada di layer domain
  /// justru untuk mendukung retry otomatis, tapi tidak pernah benar-benar
  /// dipakai di sini.
  ///
  /// Sekarang: selama attemptCount belum mencapai batas, item ditandai
  /// `waitingForInternet` (BUKAN `failed`) - ProcessSyncQueue.call()
  /// sudah lama mem-filter status ini sebagai kandidat percobaan
  /// otomatis berikutnya (polling background tiap 2 menit atau saat
  /// konektivitas pulih), jadi kegagalan transien kini bisa pulih
  /// sendiri tanpa aksi user. `failed` (butuh retry manual lewat Sync
  /// Center) kini betul-betul berarti "sudah dicoba otomatis 5x dan
  /// tetap gagal", bukan "gagal sekali".
  Future<SyncRecordModel> _recordAttemptFailure(
    SyncRecordEntity record,
    String errorMessage, {
    bool forceFailedImmediately = false,
  }) async {
    final newAttemptCount = record.attemptCount + 1;
    final willAutoRetry =
        !forceFailedImmediately &&
        newAttemptCount < SyncRecordEntity.maxAutoRetryAttempts;

    final updated = SyncRecordModel.fromEntity(
      record.copyWith(
        status: willAutoRetry
            ? SyncStatus.waitingForInternet
            : SyncStatus.failed,
        attemptCount: newAttemptCount,
        lastAttemptAt: DateTime.now(),
        lastErrorMessage: errorMessage,
      ),
    );
    await _localDataSource.updateRecord(updated);
    return updated;
  }

  /// recoverInterruptedUploads
  /// ----------------------------------------------------------------------
  /// SEBELUM ini, item yang ditandai `uploading` lalu aplikasinya mati di
  /// tengah upload MACET PERMANEN: ProcessSyncQueue hanya memproses
  /// `pendingUpload`/`waitingForInternet`, dan Sync Center hanya
  /// menampilkan "Coba Lagi" untuk `failed` - bukti tsb tidak pernah
  /// sampai ke server tanpa disadari user.
  ///
  /// Percobaan yang terputus DIHITUNG sebagai satu percobaan (lewat
  /// _recordAttemptFailure): jika upload itu sendiri yang membuat
  /// aplikasi crash (mis. file video sangat besar), item berhenti di
  /// `failed` setelah batas percobaan, bukan berputar crash tanpa akhir.
  /// Pengiriman ulang aman karena server idempoten per `id` record lokal.
  @override
  Future<Either<Failure, int>> recoverInterruptedUploads() async {
    try {
      final records = await _localDataSource.getAll();
      var recovered = 0;
      for (final record in records) {
        if (record.status != SyncStatus.uploading ||
            _inFlightRecordIds.contains(record.id)) {
          continue;
        }
        final reachesLimit =
            record.attemptCount + 1 >= SyncRecordEntity.maxAutoRetryAttempts;
        await _recordAttemptFailure(
          record,
          reachesLimit
              ? 'Pengiriman berulang kali terputus. Ketuk "Coba Lagi" untuk mengirim ulang.'
              : 'Pengiriman sebelumnya terputus. Data akan dicoba kirim lagi.',
        );
        recovered++;
      }
      return Right(recovered);
    } catch (_) {
      return const Left(LocalStorageFailure());
    }
  }

  @override
  Future<Either<Failure, void>> retryRecord(String recordId) async {
    final record = await _localDataSource.getById(recordId);
    if (record == null) {
      return const Left(SyncQueueFailure('Data antrian tidak ditemukan.'));
    }

    // Sedang dikirim - jangan timpa statusnya jadi pendingUpload di
    // tengah upload yang masih berjalan.
    if (_inFlightRecordIds.contains(recordId)) {
      return const Right(null);
    }

    // Reset attemptCount agar item yang sudah exceeds retry limit bisa
    // masuk kembali ke proses otomatis berikutnya, sekaligus langsung
    // dicoba sekali di sini atas permintaan eksplisit user.
    final reset = SyncRecordModel.fromEntity(
      record.copyWith(status: SyncStatus.pendingUpload, attemptCount: 0),
    );
    await _localDataSource.updateRecord(reset);

    final result = await processRecord(recordId);
    return result.fold((f) => Left(f), (_) => const Right(null));
  }

  /// Menerjemahkan error teknis Dio menjadi pesan Bahasa Indonesia yang
  /// manusiawi, sesuai kamus UX Copywriting (Bagian 17 spesifikasi) -
  /// TIDAK PERNAH menampilkan istilah seperti "DioException" atau kode
  /// HTTP mentah ke user.
  String _mapDioErrorToUserMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Koneksi terlalu lambat. Data akan dicoba kirim lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak ada internet. Data akan dicoba kirim lagi.';
      default:
        if (e.response?.statusCode == 409) {
          return 'Data ini tampaknya sudah pernah dikirim sebelumnya.';
        }
        if (e.response?.statusCode == 401) {
          return 'Sesi login sudah berakhir. Silakan login ulang untuk mengirim data ini.';
        }
        return 'Data belum berhasil dikirim.';
    }
  }
}
