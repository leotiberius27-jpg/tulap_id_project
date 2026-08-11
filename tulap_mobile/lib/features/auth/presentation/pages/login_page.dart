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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<LoginController>(
          builder: (context, controller, _) {
            final state = controller.state;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tulap.id',
                        style: AppTypography.display.copyWith(color: AppColors.primary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Tugas Lapangan, Disederhanakan.',
                        style: AppTypography.bodySecondary,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Email wajib diisi.' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Password wajib diisi.' : null,
                        onFieldSubmitted: (_) => _submit(controller),
                      ),
                      if (state.status == LoginStatus.error) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          state.errorMessage ?? 'Email atau password salah.',
                          style: AppTypography.small.copyWith(color: AppColors.danger),
                          textAlign: TextAlign.center,
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Masuk'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
