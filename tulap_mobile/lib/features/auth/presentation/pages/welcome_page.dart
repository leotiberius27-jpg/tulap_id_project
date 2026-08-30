import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/security/biometric_auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/micro_interactions.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/get_biometric_greeting_user.dart';
import '../../domain/usecases/restore_biometric_session.dart';
import '../controllers/welcome_controller.dart';
import 'login_page.dart';

/// WelcomePage
/// ----------------------------------------------------------------------
/// Layar Pre-Login / Sambutan resmi Tulap.id:
/// - Layer Belakang: Hero Video Background (`karakter_yang_memengang_handph.mp4`)
///   berputar otomatis, loop, mute, offline, non-interaktif (`IgnorePointer`).
/// - Layer Depan:
///   * Header atas: Tulap.id brand & Dynamic Online/Offline status pill.
///   * Area visual karakter: wajah, kepala, torso, tangan, dan handphone tampil proporsional.
///   * Panel bawah: Kartu putih melengkung Akses Cepat (Tugas Saya, Kamera Lokasi,
///     Scan Nota, Sinkronisasi) + Tombol Masuk Utama & Biometrik.
///   * Kaki/bagian bawah tubuh karakter tertutup secara natural di belakang kartu.
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

class _WelcomeViewState extends State<_WelcomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.entrance,
    );

    final cardCurve = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: AppMotion.standard),
    );

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

  void _openLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(slideFadeRoute(LoginPage(onLoginSuccess: widget.onLoginSuccess)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else if (!controller.state.biometricAvailable) {
      _openLogin(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isShort = screenHeight < 680;
    final isNarrow = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFF0056D2),
      body: Consumer<WelcomeController>(
        builder: (context, controller, _) {
          final state = controller.state;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ========================================================
              // LAYER BELAKANG: CLEAN BRAND GRADIENT (Distraction-Free)
              // ========================================================
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF003E9A),
                        Color(0xFF0056D2),
                        Color(0xFF1E88E5),
                      ],
                    ),
                  ),
                ),
              ),

              // ========================================================
              // LAYER DEPAN: HEADER ATAS (Tulap.id & Status Online)
              // ========================================================
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isNarrow ? 14 : 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Tulap.id Brand
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'Tulap.id',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x60000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Tugas Lapangan dalam Kendali',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xE0FFFFFF),
                                  shadows: [
                                    Shadow(
                                      color: Color(0x60000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Dynamic Online / Offline Pill
                        _OnlinePill(isOnline: state.isOnline),
                      ],
                    ),
                  ),
                ),
              ),

              // ========================================================
              // LAYER DEPAN: PANEL AKSES CEPAT & TOMBOL MASUK + BIOMETRIK
              // ========================================================
              Align(
                alignment: Alignment.bottomCenter,
                child: FadeTransition(
                  opacity: _cardFade,
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 520),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x2A003680),
                            blurRadius: 30,
                            offset: Offset(0, -10),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(
                        isNarrow ? 14 : 20,
                        isShort ? 14 : 18,
                        isNarrow ? 14 : 20,
                        mediaQuery.padding.bottom > 0
                            ? mediaQuery.padding.bottom + (isShort ? 6 : 12)
                            : (isShort ? 18 : 24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Card Akses Cepat + Info Tooltip
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Akses Cepat',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F1E36),
                                ),
                              ),
                              SizedBox(width: 6),
                              Tooltip(
                                message:
                                    'Masuk terlebih dahulu untuk memakai fitur ini',
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  size: 18,
                                  color: Color(0xFF0D6EFD),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isShort ? 12 : 16),

                          // 4 Ikon Fitur Akses Cepat
                          Row(
                            children: [
                              Expanded(
                                child: _QuickPreviewIcon(
                                  icon: Icons.assignment_turned_in_rounded,
                                  badgeIcon: Icons.check_circle_rounded,
                                  badgeColor: const Color(0xFF0D6EFD),
                                  label: 'Tugas Saya',
                                  isCompact: isShort || isNarrow,
                                  onTap: () => _openLogin(context),
                                ),
                              ),
                              Expanded(
                                child: _QuickPreviewIcon(
                                  icon: Icons.photo_camera_rounded,
                                  badgeIcon: Icons.location_on_rounded,
                                  badgeColor: const Color(0xFF0D6EFD),
                                  label: 'Kamera Lokasi',
                                  isCompact: isShort || isNarrow,
                                  onTap: () => _openLogin(context),
                                ),
                              ),
                              Expanded(
                                child: _QuickPreviewIcon(
                                  icon: Icons.document_scanner_rounded,
                                  label: 'Scan Nota',
                                  isCompact: isShort || isNarrow,
                                  onTap: () => _openLogin(context),
                                ),
                              ),
                              Expanded(
                                child: _QuickPreviewIcon(
                                  icon: Icons.cloud_sync_rounded,
                                  badgeIcon: Icons.check_circle_rounded,
                                  badgeColor: const Color(0xFF10B981),
                                  label: 'Sinkronisasi',
                                  isCompact: isShort || isNarrow,
                                  onTap: () => _openLogin(context),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isShort ? 14 : 20),

                          // Baris Tombol Masuk & Biometrik
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: isShort ? 48 : 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D6EFD),
                                      foregroundColor: Colors.white,
                                      elevation: 3,
                                      shadowColor: const Color(0x600D6EFD),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    onPressed: () => _openLogin(context),
                                    child: const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontFamily: AppTypography.fontFamily,
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _BiometricButton(
                                size: isShort ? 48 : 52,
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
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseDot(
            color: isOnline ? const Color(0xFF10B981) : AppColors.danger,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
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
  final bool isCompact;
  final VoidCallback onTap;

  const _QuickPreviewIcon({
    required this.icon,
    this.badgeIcon,
    this.badgeColor,
    required this.label,
    this.isCompact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final circleSize = isCompact ? 50.0 : 56.0;
    final iconSize = isCompact ? 24.0 : 27.0;

    return TapScale(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1FF),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0D6EFD,
                          ).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF0D6EFD),
                      size: iconSize,
                    ),
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
                          size: 14,
                          color: badgeColor ?? const Color(0xFF0D6EFD),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: isCompact ? 10.5 : 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F1E36),
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
  final double size;
  final bool isLoading;
  final VoidCallback onTap;

  const _BiometricButton({
    this.size = 52,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }
}
