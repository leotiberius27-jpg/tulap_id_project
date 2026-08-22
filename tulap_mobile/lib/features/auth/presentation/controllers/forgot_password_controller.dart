import 'package:flutter/foundation.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/reset_password.dart';

enum ForgotPasswordStep { requestCode, confirmReset }
enum ForgotPasswordStatus { idle, submitting, error, done }

class ForgotPasswordState {
  final ForgotPasswordStep step;
  final ForgotPasswordStatus status;
  final String? message;
  final String? errorMessage;

  const ForgotPasswordState({
    this.step = ForgotPasswordStep.requestCode,
    this.status = ForgotPasswordStatus.idle,
    this.message,
    this.errorMessage,
  });
}

/// ForgotPasswordController
/// ----------------------------------------------------------------------
/// Dua langkah: (1) minta kode OTP 6-digit dikirim ke email, (2) tukar
/// kode + password baru. Mobile belum punya deep link/app-link, jadi
/// user MENYALIN kode dari email lalu memasukkannya manual - bukan tautan
/// yang otomatis membuka app (lihat catatan yang sama di backend
/// AuthService.forgotPassword).
/// ----------------------------------------------------------------------
class ForgotPasswordController extends ChangeNotifier {
  final ForgotPassword _forgotPassword;
  final ResetPassword _resetPassword;

  ForgotPasswordState _state = const ForgotPasswordState();
  ForgotPasswordState get state => _state;

  ForgotPasswordController({
    required ForgotPassword forgotPassword,
    required ResetPassword resetPassword,
  })  : _forgotPassword = forgotPassword,
        _resetPassword = resetPassword;

  void _update(ForgotPasswordState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<bool> requestCode(String email) async {
    _update(const ForgotPasswordState(status: ForgotPasswordStatus.submitting));

    final result = await _forgotPassword(email);

    return result.fold(
      (failure) {
        _update(ForgotPasswordState(
          status: ForgotPasswordStatus.error,
          errorMessage: failure.message,
        ));
        return false;
      },
      (message) {
        _update(ForgotPasswordState(
          step: ForgotPasswordStep.confirmReset,
          status: ForgotPasswordStatus.idle,
          message: message,
        ));
        return true;
      },
    );
  }

  Future<bool> confirmReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _update(ForgotPasswordState(
      step: _state.step,
      status: ForgotPasswordStatus.submitting,
    ));

    final result = await _resetPassword(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    return result.fold(
      (failure) {
        _update(ForgotPasswordState(
          step: ForgotPasswordStep.confirmReset,
          status: ForgotPasswordStatus.error,
          errorMessage: failure.message,
        ));
        return false;
      },
      (message) {
        _update(ForgotPasswordState(
          step: ForgotPasswordStep.confirmReset,
          status: ForgotPasswordStatus.done,
          message: message,
        ));
        return true;
      },
    );
  }
}
