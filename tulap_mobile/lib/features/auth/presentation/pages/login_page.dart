import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/security/oauth_sign_in_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/login_with_apple.dart';
import '../../domain/usecases/login_with_google.dart';
import '../controllers/login_controller.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

/// LoginPage
/// ----------------------------------------------------------------------
/// Form Masuk - dibuka dari tombol "Masuk" di WelcomePage. `onLoginSuccess`
/// SENGAJA berupa callback (bukan Navigator.push hardcoded ke HomePage)
/// agar fitur auth tidak bergantung langsung pada fitur home - main.dart
/// yang merangkai navigasi keduanya.
/// ----------------------------------------------------------------------
class LoginPage extends StatelessWidget {
  final ValueChanged<AuthUserEntity> onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginController>(
      create: (_) => LoginController(
        login: sl<Login>(),
        loginWithGoogle: sl<LoginWithGoogle>(),
        loginWithApple: sl<LoginWithApple>(),
        oauthSignInService: sl<OAuthSignInService>(),
      ),
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
    _onSuccess(controller);
  }

  void _onSuccess(LoginController controller) {
    final user = controller.state.user;
    if (user != null) widget.onLoginSuccess(user);
  }

  Future<void> _submitGoogle(LoginController controller) async {
    final success = await controller.submitWithGoogle();
    if (!mounted || success != true) return;
    _onSuccess(controller);
  }

  Future<void> _submitApple(LoginController controller) async {
    final success = await controller.submitWithApple();
    if (!mounted || success != true) return;
    _onSuccess(controller);
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Butuh Bantuan Masuk?'),
        content: const Text(
          'Jika Anda mengalami kendala masuk ke akun (lupa email terdaftar, '
          'akun dinonaktifkan, atau kendala lain), hubungi Admin instansi '
          'Anda untuk dibantu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Consumer<LoginController>(
        builder: (context, controller, _) {
          final state = controller.state;
          final isBusy = state.status == LoginStatus.submitting;

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tulap.id',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.iconSoftBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Masuk',
                    textAlign: TextAlign.center,
                    style: AppTypography.pageTitle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masuk untuk melanjutkan tugas lapangan Anda.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySecondary.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'Belum memiliki akun? ',
                          style: AppTypography.small,
                        ),
                        GestureDetector(
                          onTap: isBusy
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RegisterPage(
                                        onRegisterSuccess: widget.onLoginSuccess,
                                      ),
                                    ),
                                  ),
                          child: Text(
                            'Daftar',
                            style: AppTypography.small.copyWith(
                              color: AppColors.action,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Email', style: AppTypography.small.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'Masukkan email',
                            prefixIcon: Icon(Icons.mail_outline, size: 20),
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'Email wajib diisi.'
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text('Kata Sandi', style: AppTypography.small.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Masukkan kata sandi',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Kata sandi wajib diisi.'
                              : null,
                          onFieldSubmitted: (_) => _submit(controller),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isBusy
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ForgotPasswordPage(),
                                      ),
                                    ),
                            child: const Text('Lupa kata sandi?'),
                          ),
                        ),
                        if (state.status == LoginStatus.error) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dangerSoft,
                              borderRadius: BorderRadius.circular(AppRadius.small),
                            ),
                            child: Text(
                              state.errorMessage ?? 'Email atau password salah.',
                              style: AppTypography.small.copyWith(color: AppColors.danger),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        ElevatedButton(
                          onPressed: isBusy ? null : () => _submit(controller),
                          child: isBusy
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
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Text('atau masuk dengan', style: AppTypography.small),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : () => _submitGoogle(controller),
                    icon: const Icon(Icons.g_mobiledata, size: 24, color: AppColors.textPrimary),
                    label: const Text('Lanjutkan dengan Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : () => _submitApple(controller),
                    icon: const Icon(Icons.apple, size: 22, color: AppColors.textPrimary),
                    label: const Text('Lanjutkan dengan Apple'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: TextButton(
                      onPressed: () => _showHelpDialog(context),
                      child: const Text('Butuh bantuan masuk?'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Dengan masuk, Anda menyetujui Syarat Penggunaan dan '
                    'Kebijakan Privasi Tulap.id.',
                    textAlign: TextAlign.center,
                    style: AppTypography.small.copyWith(fontSize: 11),
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
