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
      final result = await _recordAttemptFailure(record, errorMessage);
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
    String errorMessage,
  ) async {
    final newAttemptCount = record.attemptCount + 1;
    final willAutoRetry =
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

  @override
  Future<Either<Failure, void>> retryRecord(String recordId) async {
    final record = await _localDataSource.getById(recordId);
    if (record == null) {
      return const Left(SyncQueueFailure('Data antrian tidak ditemukan.'));
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
        return 'Data belum berhasil dikirim.';
    }
  }
}
