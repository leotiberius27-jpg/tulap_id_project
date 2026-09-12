import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../app/presentation/main_shell.dart';
import '../../../../core/security/biometric_auth_service.dart';
import '../../../../core/security/oauth_sign_in_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/google_logo_icon.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/is_biometric_login_enabled.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/login_with_apple.dart';
import '../../domain/usecases/login_with_facebook.dart';
import '../../domain/usecases/login_with_google.dart';
import '../../domain/usecases/restore_biometric_session.dart';
import '../controllers/login_controller.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

/// LoginPage
/// ----------------------------------------------------------------------
/// Layar Masuk resmi Tulap.id (Clean, Minimal, Modern & Responsive).
/// Mengikuti struktur visual: Logo -> Selamat Datang -> Form Email/Password
/// -> Lupa Password -> Tombol Masuk -> Divider -> Login dengan Google ->
/// Quick Biometric -> Register -> Terms/Privacy.
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
        loginWithApple: sl.isRegistered<LoginWithApple>() ? sl<LoginWithApple>() : null,
        loginWithFacebook: sl.isRegistered<LoginWithFacebook>() ? sl<LoginWithFacebook>() : null,
        oauthSignInService: sl<OAuthSignInService>(),
        restoreBiometricSession: sl.isRegistered<RestoreBiometricSession>()
            ? sl<RestoreBiometricSession>()
            : null,
        isBiometricLoginEnabled: sl.isRegistered<IsBiometricLoginEnabled>()
            ? sl<IsBiometricLoginEnabled>()
            : null,
        biometricAuthService: sl.isRegistered<BiometricAuthService>()
            ? sl<BiometricAuthService>()
            : null,
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
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final success = await controller.submit(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted || !success) return;
    _onSuccess(controller);
  }

  void _onSuccess(LoginController controller) {
    final user = controller.state.user;
    if (user != null) {
      widget.onLoginSuccess(user);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _submitGoogle(
    LoginController controller, {
    bool forceAccountChooser = false,
  }) async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final success = await controller.submitWithGoogle(
      forceAccountChooser: forceAccountChooser,
    );
    if (!mounted || success != true) return;
    _onSuccess(controller);
  }

  Future<void> _submitBiometric(LoginController controller) async {
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final success = await controller.submitBiometric();
    if (!mounted || !success) return;
    _onSuccess(controller);
  }

  void _showTermsDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            title == 'Syarat Layanan'
                ? 'Tulap.id digunakan oleh petugas dinas/lapangan untuk pencatatan dan pelaporan kegiatan lapangan yang terverifikasi secara akurat. Data lokasi GPS, waktu, dan bukti foto dilindungi dengan verifikasi checksum anti-manipulasi.'
                : 'Data pribadi dan dokumentasi kegiatan lapangan diproses sesuai peraturan perlindungan data dan hanya dapat diakses oleh petugas serta verifikator yang berwenang.',
            style: const TextStyle(fontSize: 13.5, height: 1.5),
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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Nilai responsif berdasarkan ukuran layar aktual
    final isNarrow = screenWidth < 350;
    final isShort = screenHeight < 680;

    final horizontalPadding = isNarrow
        ? 14.0
        : (screenWidth > 400 ? 24.0 : 18.0);
    final cardPadding = screenWidth <= 360
        ? const EdgeInsets.symmetric(horizontal: 18, vertical: 22)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 28);
    final logoSize = isShort ? 56.0 : (isNarrow ? 60.0 : 68.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<LoginController>(
          builder: (context, controller, _) {
            final state = controller.state;
            final isBusy = state.status == LoginStatus.submitting;
            final hasError = state.status == LoginStatus.error;

            return Stack(
              children: [
                // Scrollable Form Container
                Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12172033),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. LOGO RESMI TULAP.ID
                            Center(
                              child: Container(
                                height: logoSize,
                                width: logoSize,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.iconSoftBlue.withValues(
                                    alpha: 0.6,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.assignment_turned_in_rounded,
                                      color: AppColors.primary,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isShort ? 12 : 16),

                            // 2. HEADER: SELAMAT DATANG & SUBTITLE
                            const Text(
                              'Selamat Datang',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Masuk untuk melanjutkan ke Tulap.id',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: isShort ? 16 : 22),

                            // 3. BANNER ERROR (JIKA ADA)
                            if (hasError && state.errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerSoft,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.danger,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        state.errorMessage!,
                                        style: const TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 12.5,
                                          color: AppColors.danger,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // 4. FORM INPUT (EMAIL & PASSWORD)
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Label Email
                                  const Text(
                                    'Email',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    enabled: !isBusy,
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'nama@email.com',
                                      hintStyle: const TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        color: Color(0xFF94A3B8),
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.mail_outline_rounded,
                                        color: Color(0xFF64748B),
                                        size: 20,
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: AppColors.action,
                                          width: 1.6,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Email wajib diisi';
                                      }
                                      final emailRegex = RegExp(
                                        r'^[^@]+@[^@]+\.[^@]+$',
                                      );
                                      if (!emailRegex.hasMatch(value.trim())) {
                                        return 'Format email tidak valid';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Label Password
                                  const Text(
                                    'Password',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) =>
                                        _submit(controller),
                                    enabled: !isBusy,
                                    style: const TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '••••••••',
                                      hintStyle: const TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        color: Color(0xFF94A3B8),
                                        fontSize: 14,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: Color(0xFF64748B),
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: const Color(0xFF64748B),
                                          size: 20,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        tooltip: _obscurePassword
                                            ? 'Tampilkan password'
                                            : 'Sembunyikan password',
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: AppColors.action,
                                          width: 1.6,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 6),

                                  // Lupa Password Link (Kanan Bawah)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: isBusy
                                          ? null
                                          : () => Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ForgotPasswordPage(),
                                              ),
                                            ),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Text(
                                          'Lupa password?',
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.action,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 5. TOMBOL MASUK UTAMA
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: isBusy
                                    ? null
                                    : () => _submit(controller),
                                child: isBusy
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Masuk...',
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTypography.fontFamily,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: isShort ? 14 : 18),

                            // 6. DIVIDER "atau"
                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFE2E8F0),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'atau',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 12.5,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFE2E8F0),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isShort ? 12 : 16),

                            // 7. LOGIN DENGAN GOOGLE - satu tombol gabungan
                            // (bukan dua baris terpisah): area utama masuk
                            // dengan akun yang sudah tersimpan (signInSilently
                            // di baliknya selalu mengembalikan akun yang SAMA
                            // dengan terakhir dipakai), chevron di kanan
                            // membuka pemilih akun Google untuk ganti akun -
                            // dua aksi, satu elemen visual, biar Halaman
                            // Masuk tidak terlihat penuh.
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: InkWell(
                                        borderRadius: const BorderRadius.horizontal(
                                          left: Radius.circular(14),
                                        ),
                                        onTap: isBusy
                                            ? null
                                            : () => _submitGoogle(controller),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            GoogleLogoIcon(size: 20),
                                            SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Masuk dengan Google',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontFamily:
                                                      AppTypography.fontFamily,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 26,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  Material(
                                    type: MaterialType.transparency,
                                    child: Tooltip(
                                      message: 'Gunakan akun Google lain',
                                      child: InkWell(
                                        borderRadius: const BorderRadius.horizontal(
                                          right: Radius.circular(14),
                                        ),
                                        onTap: isBusy
                                            ? null
                                            : () => _submitGoogle(
                                                  controller,
                                                  forceAccountChooser: true,
                                                ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          child: Icon(
                                            Icons.expand_more_rounded,
                                            size: 20,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 8. QUICK BIOMETRIC LOGIN (OPSIONAL JIKA AKTIF)
                            if (state.biometricAvailable) ...[
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: AppColors.iconSoftBlue
                                      .withValues(alpha: 0.4),
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.25,
                                    ),
                                    width: 1.2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: isBusy
                                    ? null
                                    : () => _submitBiometric(controller),
                                icon: const Icon(
                                  Icons.fingerprint_rounded,
                                  size: 22,
                                ),
                                label: const Text(
                                  'Masuk dengan Biometrik',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            SizedBox(height: isShort ? 14 : 18),

                            // 9. REGISTER PROMPT: "Belum punya akun? Daftar"
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    'Belum punya akun? ',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 13.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: isBusy
                                        ? null
                                        : () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => RegisterPage(
                                                onRegisterSuccess:
                                                    widget.onLoginSuccess,
                                              ),
                                            ),
                                          ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        'Daftar',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 13.5,
                                          color: AppColors.action,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // 10. TERMS & PRIVACY SUBTLE FOOTER
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  const Text(
                                    'Dengan masuk, Anda menyetujui ',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showTermsDialog(
                                      context,
                                      'Syarat Layanan',
                                    ),
                                    child: const Text(
                                      'Syarat Layanan',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    ' & ',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showTermsDialog(
                                      context,
                                      'Kebijakan Privasi',
                                    ),
                                    child: const Text(
                                      'Kebijakan Privasi',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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

                // Tombol Back di Kiri Atas (jika ada rute sebelumnya)
                if (Navigator.of(context).canPop())
                  Positioned(
                    top: 8,
                    left: 12,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 1,
                      shadowColor: const Color(0x18000000),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

}
