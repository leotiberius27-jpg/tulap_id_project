import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/firebase_email_auth_service.dart';
import 'live_tracking_page.dart';

/// FirebaseLoginPage
/// ----------------------------------------------------------------------
/// Layar login BERDIRI SENDIRI untuk modul percobaan
/// `firebase_live_tracking` - memakai Firebase Authentication langsung
/// (Email/Password + Google) lewat `FirebaseEmailAuthService`, TERPISAH
/// dari `features/auth/presentation/pages/login_page.dart` (backend
/// NestJS/JWT) yang tetap satu-satunya alur login resmi Tulap.id.
/// Diakses dari AccountPage > "MODUL PERCOBAAN (BETA)".
/// ----------------------------------------------------------------------
class FirebaseLoginPage extends StatefulWidget {
  const FirebaseLoginPage({super.key});

  @override
  State<FirebaseLoginPage> createState() => _FirebaseLoginPageState();
}

class _FirebaseLoginPageState extends State<FirebaseLoginPage> {
  final _authService = FirebaseEmailAuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Sesi Firebase sebelumnya (jika ada) langsung dilanjutkan tanpa
    // memaksa login ulang - konsisten dengan pola AuthGate di main.dart
    // untuk alur backend.
    final existingUser = _authService.currentUser;
    if (existingUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _goToTracking(existingUser);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToTracking(User user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LiveTrackingPage(user: user)),
    );
  }

  Future<void> _submitEmailForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final credential = _isRegisterMode
          ? await _authService.registerWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            )
          : await _authService.signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      if (!mounted) return;
      final user = credential.user;
      if (user != null) _goToTracking(user);
    } on FirebaseAuthFailure catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitGoogleSignIn() async {
    setState(() => _isSubmitting = true);
    try {
      final credential = await _authService.signInWithGoogle();
      if (!mounted || credential == null) return; // Dialog dibatalkan user
      final user = credential.user;
      if (user != null) _goToTracking(user);
    } on FirebaseAuthFailure catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Isi email terlebih dahulu untuk mengirim tautan reset.');
      return;
    }
    try {
      await _authService.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tautan reset kata sandi dikirim ke $email.')),
      );
    } on FirebaseAuthFailure catch (e) {
      _showError(e.message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Live Tracking (Firebase)'),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.satellite_alt_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _isRegisterMode ? 'Buat Akun Firebase' : 'Masuk Firebase',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modul percobaan - terpisah dari akun Tulap.id utama.',
                      textAlign: TextAlign.center,
                      style: AppTypography.small.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) => (value == null || !value.contains('@'))
                          ? 'Masukkan email yang valid'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata Sandi',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) => (value == null || value.length < 6)
                          ? 'Minimal 6 karakter'
                          : null,
                    ),
                    if (!_isRegisterMode) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isSubmitting ? null : _forgotPassword,
                          child: const Text('Lupa kata sandi?'),
                        ),
                      ),
                    ] else
                      const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitEmailForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isRegisterMode ? 'Daftar' : 'Masuk'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() => _isRegisterMode = !_isRegisterMode),
                      child: Text(
                        _isRegisterMode
                            ? 'Sudah punya akun? Masuk'
                            : 'Belum punya akun? Daftar',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: Divider(color: colors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'atau',
                            style: AppTypography.small.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: colors.border)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _submitGoogleSignIn,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 26),
                        label: const Text('Lanjutkan dengan Google'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
