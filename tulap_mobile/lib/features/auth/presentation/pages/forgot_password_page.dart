import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/reset_password.dart';
import '../controllers/forgot_password_controller.dart';

/// ForgotPasswordPage (Lupa Kata Sandi)
/// ----------------------------------------------------------------------
/// Dua langkah nyata (bukan info kontak admin) - minta kode OTP 6-digit
/// via email, lalu tukar kode + password baru. Lihat catatan MailerService
/// di backend: tanpa SMTP dikonfigurasi, kode di-log ke console server
/// saat development (tetap bisa diuji end-to-end).
/// ----------------------------------------------------------------------
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ForgotPasswordController>(
      create: (_) => ForgotPasswordController(
        forgotPassword: sl<ForgotPassword>(),
        resetPassword: sl<ResetPassword>(),
      ),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode(ForgotPasswordController controller) async {
    if (!_emailFormKey.currentState!.validate()) return;
    await controller.requestCode(_emailController.text.trim());
  }

  Future<void> _confirmReset(ForgotPasswordController controller) async {
    if (!_resetFormKey.currentState!.validate()) return;
    await controller.confirmReset(
      email: _emailController.text.trim(),
      code: _codeController.text.trim(),
      newPassword: _newPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lupa Kata Sandi'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<ForgotPasswordController>(
        builder: (context, controller, _) {
          final state = controller.state;
          final isBusy = state.status == ForgotPasswordStatus.submitting;

          if (state.status == ForgotPasswordStatus.done) {
            return _DoneView(message: state.message);
          }

          if (state.step == ForgotPasswordStep.requestCode) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _emailFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_reset, size: 48, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Masukkan email akun Anda. Kami akan mengirim kode reset '
                      '6-digit ke email tersebut.',
                      style: AppTypography.bodySecondary.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Email wajib diisi.' : null,
                      onFieldSubmitted: (_) => _requestCode(controller),
                    ),
                    if (state.status == ForgotPasswordStatus.error) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ErrorBanner(message: state.errorMessage),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton(
                      onPressed: isBusy ? null : () => _requestCode(controller),
                      child: isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kirim Kode Reset'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _resetFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.success),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    state.message ??
                        'Kode reset telah dikirim ke ${_emailController.text}.',
                    style: AppTypography.bodySecondary.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Kode Reset (6 digit)',
                      prefixIcon: Icon(Icons.pin_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().length != 6)
                        ? 'Kode reset harus 6 digit.'
                        : null,
                  ),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Baru',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'Kata sandi minimal 8 karakter.'
                        : null,
                    onFieldSubmitted: (_) => _confirmReset(controller),
                  ),
                  if (state.status == ForgotPasswordStatus.error) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ErrorBanner(message: state.errorMessage),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: isBusy ? null : () => _confirmReset(controller),
                    child: isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Ganti Kata Sandi'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String? message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        message ?? 'Terjadi kesalahan.',
        style: AppTypography.small.copyWith(color: AppColors.danger),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  final String? message;
  const _DoneView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 56, color: AppColors.success),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? 'Kata sandi berhasil diganti.',
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kembali ke Masuk'),
            ),
          ],
        ),
      ),
    );
  }
}
