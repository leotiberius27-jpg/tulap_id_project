import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/security/oauth_sign_in_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/google_logo_icon.dart';
import '../../../../core/widgets/micro_interactions.dart';
import '../../../../core/widgets/topographic_background.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/login_with_apple.dart';
import '../../domain/usecases/login_with_google.dart';
import '../controllers/login_controller.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

/// LoginPage
/// ----------------------------------------------------------------------
/// Form Masuk Tulap.id yang mengikuti persis referensi visual kartu putih
/// melayang dengan latar topografi halus, logo Tulap.id, badge verifikasi,
/// input Email & Password dengan icon, tombol aksi utama, dan OAuth.
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

class _LoginViewState extends State<_LoginView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _shakeController;
  LoginStatus _previousStatus = LoginStatus.idle;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _maybeShake(LoginStatus status) {
    if (status == LoginStatus.error && _previousStatus != LoginStatus.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _shakeController.forward(from: 0);
      });
    }
    _previousStatus = status;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_outline_rounded, color: Color(0xFF0D6EFD)),
            SizedBox(width: 8),
            Text('Bantuan Masuk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Jika Anda mengalami kendala saat masuk (lupa email terdaftar, '
          'akun belum diaktivasi, atau kendala teknis lainnya), silakan '
          'hubungi Administrator instansi Anda atau kirim email ke support@tulap.id.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D6EFD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            title == 'Syarat Penggunaan'
                ? 'Tulap.id digunakan oleh pegawai instansi untuk pelaporan tugas lapangan secara akurat dan terverifikasi. Data lokasi, waktu, dan bukti foto dilindungi dengan enkripsi dan integritas anti-manipulasi.'
                : 'Data pribadi dan dokumentasi kegiatan lapangan diproses sesuai UU PDP No. 27/2022 dan hanya diakses oleh verifikator instansi yang berwenang.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF4FC),
      body: Consumer<LoginController>(
        builder: (context, controller, _) {
          final state = controller.state;
          final isBusy = state.status == LoginStatus.submitting;
          final hasError = state.status == LoginStatus.error;
          _maybeShake(state.status);

          return TopographicBackground(
            strokeColor: const Color(0xFF0D6EFD),
            opacity: 0.08,
            child: SafeArea(
              child: Stack(
                children: [
                  // Tombol Kembali di Pojok Kiri Atas
                  Positioned(
                    top: 12,
                    left: 16,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 2,
                      shadowColor: const Color(0x180D6EFD),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF0D6EFD),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Konten Form dalam Kartu Melayang
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 56, 18, 20),
                      child: AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          final offset = math.sin(_shakeController.value * math.pi * 4) * 8 * (1 - _shakeController.value);
                          return Transform.translate(
                            offset: Offset(offset, 0),
                            child: child,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 420),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x140D6EFD),
                                blurRadius: 28,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Judul Brand Tulap.id
                              const Text(
                                'Tulap.id',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D6EFD),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Logo Resmi Tulap.id
                              Center(
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F1FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 42,
                                    height: 42,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Judul Halaman & Subjudul
                              const Text(
                                'Masuk',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F1E36),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Masuk untuk melanjutkan tugas lapangan Anda.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Navigasi ke Halaman Pendaftaran
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      'Belum memiliki akun? ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
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
                                      child: const Text(
                                        'Daftar',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF0D6EFD),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Notifikasi Banner Error
                              if (hasError && state.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFCA5A5)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          state.errorMessage!,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: Color(0xFFB91C1C),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // Form Input
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Label Email
                                    const Text(
                                      'Email',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F1E36),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      enabled: !isBusy,
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan email',
                                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                        prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF0D6EFD), size: 20),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.6),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
                                        if (!value.contains('@')) return 'Format email tidak valid';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),

                                    // Label Kata Sandi
                                    const Text(
                                      'Kata Sandi',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F1E36),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _submit(controller),
                                      enabled: !isBusy,
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan kata sandi',
                                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 20),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                            color: const Color(0xFF64748B),
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.6),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Kata sandi wajib diisi';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 6),

                                    // Lupa Kata Sandi
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                        onTap: isBusy
                                            ? null
                                            : () => Navigator.of(context).push(
                                                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                                                ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 4),
                                          child: Text(
                                            'Lupa kata sandi?',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF0D6EFD),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    // Tombol Masuk Utama
                                    SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0D6EFD),
                                          foregroundColor: Colors.white,
                                          elevation: 3,
                                          shadowColor: const Color(0x600D6EFD),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        onPressed: isBusy ? null : () => _submit(controller),
                                        child: isBusy
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Masuk',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Divider "atau masuk dengan"
                              Row(
                                children: [
                                  const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'atau masuk dengan',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: const Color(0xFF64748B).withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Tombol Masuk Google
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F1E36),
                                  minimumSize: const Size.fromHeight(50),
                                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: isBusy ? null : () => _submitGoogle(controller),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GoogleLogoIcon(size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Lanjutkan dengan Google',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F1E36),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Tombol Masuk Apple
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F1E36),
                                  minimumSize: const Size.fromHeight(50),
                                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: isBusy ? null : () => _submitApple(controller),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.apple, color: Colors.black, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Lanjutkan dengan Apple',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F1E36),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Link Bantuan
                              Center(
                                child: GestureDetector(
                                  onTap: () => _showHelpDialog(context),
                                  child: const Text(
                                    'Butuh bantuan masuk?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D6EFD),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Syarat & Kebijakan Privasi
                              Center(
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  children: [
                                    const Text(
                                      'Dengan masuk, Anda menyetujui ',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showTermsDialog(context, 'Syarat Penggunaan'),
                                      child: const Text(
                                        'Syarat Penggunaan',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF0D6EFD),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      ' dan ',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                    GestureDetector(
                                      onTap: () => _showTermsDialog(context, 'Kebijakan Privasi'),
                                      child: const Text(
                                        'Kebijakan Privasi',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Color(0xFF0D6EFD),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      ' Tulap.id.',
                                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
