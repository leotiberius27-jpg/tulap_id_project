import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/security/biometric_auth_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/auth_user_entity.dart';
import '../../domain/usecases/get_biometric_greeting_user.dart';
import '../../domain/usecases/restore_biometric_session.dart';
import '../controllers/welcome_controller.dart';
import 'login_page.dart';

/// WelcomePage
/// ----------------------------------------------------------------------
/// Layar sambutan SEBELUM form login - identitas brand, sapaan personal
/// (dari salinan sesi biometrik jika pernah diaktifkan), status koneksi
/// NYATA, dan jalan pintas "Masuk Cepat dengan Biometrik". Semua ikon
/// "Akses Cepat" di sini murni pratinjau (tugas belum bisa dibuka tanpa
/// login) - ditekan akan mengarahkan ke form Masuk, bukan tombol mati.
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

class _WelcomeView extends StatelessWidget {
  final ValueChanged<AuthUserEntity> onLoginSuccess;

  const _WelcomeView({required this.onLoginSuccess});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 19) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  void _openLogin(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginPage(onLoginSuccess: onLoginSuccess),
      ),
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
      onLoginSuccess(user);
      return;
    }

    final error = controller.state.biometricError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WelcomeController>(
        builder: (context, controller, _) {
          final state = controller.state;

          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: _OnlinePill(isOnline: state.isOnline),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const Text(
                            'Tulap.id',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tugas Lapangan dalam Kendali',
                            style: AppTypography.heroSubtitle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            state.greetingUser != null
                                ? '$_greeting, ${state.greetingUser!.fullName.split(' ').first}!'
                                : '$_greeting!',
                            style: AppTypography.heroName,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Siap menjalankan tugas hari ini?',
                            style: AppTypography.heroGreeting,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const _FieldToolsIllustration(),
                          const SizedBox(height: AppSpacing.xl),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadowSoft,
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Akses Cepat',
                                      style: AppTypography.sectionLabel.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Tooltip(
                                      message:
                                          'Masuk terlebih dahulu untuk memakai fitur ini',
                                      child: Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _QuickPreviewIcon(
                                      icon: Icons.assignment_turned_in_outlined,
                                      label: 'Tugas Saya',
                                      background: AppColors.iconSoftBlue,
                                      onTap: () => _openLogin(context),
                                    ),
                                    _QuickPreviewIcon(
                                      icon: Icons.add_a_photo_outlined,
                                      label: 'Kamera Lokasi',
                                      background: AppColors.iconSoftCyan,
                                      onTap: () => _openLogin(context),
                                    ),
                                    _QuickPreviewIcon(
                                      icon: Icons.receipt_long_outlined,
                                      label: 'Scan Nota',
                                      background: AppColors.iconSoftTeal,
                                      onTap: () => _openLogin(context),
                                    ),
                                    _QuickPreviewIcon(
                                      icon: Icons.sync_outlined,
                                      label: 'Sinkronisasi',
                                      background: AppColors.iconSoftIndigo,
                                      onTap: () => _openLogin(context),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                            ),
                            onPressed: () => _openLogin(context),
                            child: const Text('Masuk'),
                          ),
                        ),
                        if (state.biometricAvailable) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _BiometricButton(
                            isLoading: state.isRestoringBiometric,
                            onTap: () => _tryBiometric(context, controller),
                          ),
                        ],
                      ],
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

class _OnlinePill extends StatelessWidget {
  final bool isOnline;
  const _OnlinePill({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: AppTypography.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// _FieldToolsIllustration
/// ----------------------------------------------------------------------
/// Pengganti ilustrasi foto/karakter (tidak ada aset ilustrasi asli
/// milik Tulap.id yang bisa dipakai) - kluster ikon merepresentasikan
/// alat kerja lapangan yang SUDAH nyata ada di app (kamera geotag, scan
/// OCR, lokasi, sinkronisasi), konsisten dengan bahasa visual "ikon
/// dalam lingkaran soft" yang sudah dipakai di seluruh app.
/// ----------------------------------------------------------------------
class _FieldToolsIllustration extends StatelessWidget {
  const _FieldToolsIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(Icons.location_city, color: Colors.white, size: 40),
          const Positioned(
            left: 8,
            top: 4,
            child: _FloatingIcon(icon: Icons.camera_alt_outlined),
          ),
          const Positioned(
            right: 8,
            top: 4,
            child: _FloatingIcon(icon: Icons.document_scanner_outlined),
          ),
          const Positioned(
            left: 24,
            bottom: 0,
            child: _FloatingIcon(icon: Icons.location_on_outlined),
          ),
          const Positioned(
            right: 24,
            bottom: 0,
            child: _FloatingIcon(icon: Icons.cloud_sync_outlined),
          ),
        ],
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  const _FloatingIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}

class _QuickPreviewIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback onTap;

  const _QuickPreviewIcon({
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.action, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: isLoading ? null : onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.fingerprint, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
