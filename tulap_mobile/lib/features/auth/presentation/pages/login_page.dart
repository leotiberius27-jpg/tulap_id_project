import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/login.dart';
import '../controllers/login_controller.dart';

/// LoginPage
/// ----------------------------------------------------------------------
/// Titik masuk aplikasi (Bagian 8 Mobile Sitemap: `Login -> Beranda`).
/// Tidak butuh entry page terpisah seperti GeotagCameraEntryPage/
/// ReceiptScannerEntryPage karena LoginController tidak bergantung pada
/// resource async (CameraController) - halaman ini membungkus
/// Provider-nya sendiri, sama seperti GeotagCameraPage.
///
/// `onLoginSuccess` SENGAJA berupa callback (bukan Navigator.push
/// hardcoded ke HomePage di sini) agar fitur auth tidak bergantung
/// langsung pada fitur home - main.dart yang merangkai navigasi
/// keduanya (lihat Bagian 8 spesifikasi: main.dart mengatur alur
/// Login -> Beranda).
/// ----------------------------------------------------------------------
class LoginPage extends StatelessWidget {
  final ValueChanged<AuthUserEntity> onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginController>(
      create: (_) => LoginController(login: sl<Login>()),
      child: _LoginView(onLoginSuccess: onLoginSuccess),
    );
  }
}

class _LoginView extends StatefulWidget {
  final ValueChanged<AuthUserEntity> onLoginSuccess;

  const _LoginView({required this.onLoginSuccess});

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(LoginController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.submit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || !success) return;

    final user = controller.state.user;
    if (user != null) {
      widget.onLoginSuccess(user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Consumer<LoginController>(
            builder: (context, controller, _) {
              final state = controller.state;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowSoft,
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Image.asset('assets/images/logo.png'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('TULAP.ID', style: AppTypography.brandTitle),
                      const SizedBox(height: 6),
                      const Text(
                        'Tugas Lapangan, Disederhanakan.',
                        style: AppTypography.heroSubtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppRadius.cardLarge,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowSoft,
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Masuk ke Akun Anda',
                                style: AppTypography.sectionTitle,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(
                                    Icons.mail_outline,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? 'Email wajib diisi.'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePassword =
                                          !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (value) =>
                                    (value == null || value.isEmpty)
                                    ? 'Password wajib diisi.'
                                    : null,
                                onFieldSubmitted: (_) => _submit(controller),
                              ),
                              if (state.status == LoginStatus.error) ...[
                                const SizedBox(height: AppSpacing.md),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.sm,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerSoft,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.small,
                                    ),
                                  ),
                                  child: Text(
                                    state.errorMessage ??
                                        'Email atau password salah.',
                                    style: AppTypography.small.copyWith(
                                      color: AppColors.danger,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.lg),
                              ElevatedButton(
                                onPressed: state.status == LoginStatus.submitting
                                    ? null
                                    : () => _submit(controller),
                                child: state.status == LoginStatus.submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Masuk'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
