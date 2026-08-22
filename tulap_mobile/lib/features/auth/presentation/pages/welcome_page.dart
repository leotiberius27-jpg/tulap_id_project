import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/security/biometric_auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/micro_interactions.dart';
import '../../../../core/widgets/topographic_background.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/get_biometric_greeting_user.dart';
import '../../domain/usecases/restore_biometric_session.dart';
import '../controllers/welcome_controller.dart';
import 'login_page.dart';

/// WelcomePage
/// ----------------------------------------------------------------------
/// Layar sambutan awal Tulap.id yang mengikuti persis referensi visual:
/// - Latar gradien biru royal dengan kontur topografi halus
/// - Status pill Online di pojok kanan atas
/// - Brand Tulap.id & Sapaan personal (Halo, Leonardo!)
/// - Ilustrasi 2 petugas lapangan dengan floating tool icons (full width)
/// - Kartu putih melengkung di bawah dengan menu Akses Cepat & tombol Masuk + Biometrik
/// ----------------------------------------------------------------------
class WelcomePage extends StatelessWidget {
  final ValueChanged<AuthUserEntity> onLoginSuccess;

  const WelcomePage({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WelcomeController>(
      create: (_) => WelcomeController(
        networkInfo: sl<NetworkInfo>(),
        getBiometricGreetingUser: sl<GetBiometricGreetingUser>(),
        restoreBiometricSession: sl<RestoreBiometricSession>(),
        biometricAuthService: sl<BiometricAuthService>(),
      ),
      child: _WelcomeView(onLoginSuccess: onLoginSuccess),
    );
  }
}

class _WelcomeView extends StatefulWidget {
  final ValueChanged<AuthUserEntity> onLoginSuccess;

  const _WelcomeView({required this.onLoginSuccess});

  @override
  State<_WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<_WelcomeView> with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _headlineFade;
  late final Animation<Offset> _headlineSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: AppMotion.entrance);

    final headlineCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.65, curve: AppMotion.standard),
    );
    final cardCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 1.0, curve: AppMotion.standard),
    );

    _headlineFade = headlineCurve;
    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(headlineCurve);
    _cardFade = cardCurve;
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(cardCurve);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      slideFadeRoute(LoginPage(onLoginSuccess: widget.onLoginSuccess)),
    );
  }

  Future<void> _tryBiometric(
    BuildContext context,
    WelcomeController controller,
  ) async {
    HapticFeedback.mediumImpact();
    final user = await controller.authenticateWithBiometric();
    if (!context.mounted) return;

    if (user != null) {
      widget.onLoginSuccess(user);
      return;
    }

    final error = controller.state.biometricError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else if (!controller.state.biometricAvailable) {
      // Jika biometrik belum didaftarkan di perangkat
      _openLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF005BD6),
      body: Consumer<WelcomeController>(
        builder: (context, controller, _) {
          final state = controller.state;
          final userName = state.greetingUser != null
              ? state.greetingUser!.fullName.split(' ').first
              : 'Leonardo';

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0055D2),
                  Color(0xFF0064EB),
                  Color(0xFF0D6EFD),
                ],
              ),
            ),
            child: TopographicBackground(
              strokeColor: Colors.white,
              opacity: 0.12,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Area Atas (Online pill, Header Tulap.id & Sapaan)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 6),
                          // Online pill
                          Align(
                            alignment: Alignment.centerRight,
                            child: _OnlinePill(isOnline: state.isOnline),
                          ),
                          const SizedBox(height: 8),
                          // Header Tulap.id
                          FadeTransition(
                            opacity: _headlineFade,
                            child: SlideTransition(
                              position: _headlineSlide,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/logo.png',
                                        width: 36,
                                        height: 36,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Tulap.id',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.6,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tugas Lapangan dalam Kendali',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Halo, $userName!',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Siap menjalankan tugas hari ini?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Area Tengah: Ilustrasi Petugas Lapangan Edge-to-Edge
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Image.asset(
                          'assets/images/hero_illustration.png',
                          fit: BoxFit.contain,
                          width: double.infinity,
                          alignment: Alignment.bottomCenter,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/referensi/01.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ),

                    // Area Bawah: Kartu Putih Melengkung (Akses Cepat & Tombol Masuk + Biometrik)
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(34),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x28003680),
                                blurRadius: 28,
                                offset: Offset(0, -8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Judul Akses Cepat + Icon info
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Akses Cepat',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F1E36),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Tooltip(
                                    message: 'Masuk terlebih dahulu untuk memakai fitur ini',
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      size: 19,
                                      color: const Color(0xFF0D6EFD),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // 4 Ikon Fitur Akses Cepat
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _QuickPreviewIcon(
                                    icon: Icons.assignment_turned_in_rounded,
                                    badgeIcon: Icons.check_circle_rounded,
                                    badgeColor: const Color(0xFF0D6EFD),
                                    label: 'Tugas Saya',
                                    onTap: () => _openLogin(context),
                                  ),
                                  _QuickPreviewIcon(
                                    icon: Icons.photo_camera_rounded,
                                    badgeIcon: Icons.location_on_rounded,
                                    badgeColor: const Color(0xFF0D6EFD),
                                    label: 'Kamera Lokasi',
                                    onTap: () => _openLogin(context),
                                  ),
                                  _QuickPreviewIcon(
                                    icon: Icons.document_scanner_rounded,
                                    label: 'Scan Nota',
                                    onTap: () => _openLogin(context),
                                  ),
                                  _QuickPreviewIcon(
                                    icon: Icons.cloud_sync_rounded,
                                    badgeIcon: Icons.check_circle_rounded,
                                    badgeColor: const Color(0xFF10B981),
                                    label: 'Sinkronisasi',
                                    onTap: () => _openLogin(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Baris Tombol Masuk & Biometrik
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 52,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0D6EFD),
                                          foregroundColor: Colors.white,
                                          elevation: 4,
                                          shadowColor: const Color(0x600D6EFD),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        onPressed: () => _openLogin(context),
                                        child: const Text(
                                          'Masuk',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _BiometricButton(
                                    isLoading: state.isRestoringBiometric,
                                    onTap: () => _tryBiometric(context, controller),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OnlinePill extends StatelessWidget {
  final bool isOnline;
  const _OnlinePill({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseDot(color: isOnline ? const Color(0xFF10B981) : AppColors.danger),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPreviewIcon extends StatelessWidget {
  final IconData icon;
  final IconData? badgeIcon;
  final Color? badgeColor;
  final String label;
  final VoidCallback onTap;

  const _QuickPreviewIcon({
    required this.icon,
    this.badgeIcon,
    this.badgeColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D6EFD).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: const Color(0xFF0D6EFD), size: 28),
                  ),
                  if (badgeIcon != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          badgeIcon,
                          size: 15,
                          color: badgeColor ?? const Color(0xFF0D6EFD),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F1E36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _BiometricButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF0D6EFD),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x600D6EFD),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.fingerprint_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
        ),
      ),
    );
  }
}
