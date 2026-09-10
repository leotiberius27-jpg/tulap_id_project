import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/payment_method_type.dart';
import '../../domain/entities/payment_transaction_entity.dart';
import '../../domain/entities/plan_code.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payments_remote_datasource.dart';
import '../models/payment_transaction_model.dart';

/// PaymentRepositoryImpl
/// ----------------------------------------------------------------------
/// TIDAK ADA cache/fallback lokal di sini SENGAJA - berbeda dengan
/// SubscriptionRepositoryImpl. Status pembayaran HARUS selalu berasal
/// dari backend (Bagian 17 & 29 instruksi payment); kegagalan jaringan
/// ditampilkan sebagai "tidak dapat memeriksa pembayaran", BUKAN
/// ditebak dari data lama.
/// ----------------------------------------------------------------------
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentsRemoteDataSource _remoteDataSource;

  PaymentRepositoryImpl({required PaymentsRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, PaymentTransactionEntity>> checkout({
    required PlanCode planCode,
    required BillingCycle billingCycle,
    required PaymentMethodType paymentMethod,
    required String checkoutAttemptId,
    String? vaBank,
  }) async {
    try {
      final json = await _remoteDataSource.checkout(
        planCode: planCode,
        billingCycle: billingCycle,
        paymentMethod: paymentMethod,
        checkoutAttemptId: checkoutAttemptId,
        vaBank: vaBank,
      );
      return Right(PaymentTransactionModel.fromJson(json));
    } catch (e) {
      return Left(
        ServerFailure(extractApiErrorMessage(e, 'Gagal membuat transaksi pembayaran.')),
      );
    }
  }

  @override
  Future<Either<Failure, List<PaymentTransactionEntity>>> getHistory() async {
    try {
      final list = await _remoteDataSource.getHistory();
      return Right(
        list
            .map((e) => PaymentTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
    } catch (e) {
      return Left(ServerFailure(extractApiErrorMessage(e, 'Gagal memuat riwayat pembayaran.')));
    }
  }

  @override
  Future<Either<Failure, PaymentTransactionEntity>> getDetail(String publicReference) async {
    try {
      final json = await _remoteDataSource.getDetail(publicReference);
      return Right(PaymentTransactionModel.fromJson(json));
    } catch (e) {
      return Left(NotFoundFailure(extractApiErrorMessage(e, 'Transaksi tidak ditemukan.')));
    }
  }

  @override
  Future<Either<Failure, PaymentTransactionEntity>> checkStatus(String publicReference) async {
    try {
      final json = await _remoteDataSource.checkStatus(publicReference);
      return Right(PaymentTransactionModel.fromJson(json));
    } catch (e) {
      return Left(
        ServerFailure(
          extractApiErrorMessage(e, 'Tidak dapat memeriksa pembayaran saat ini.'),
        ),
      );
    }
  }
}
