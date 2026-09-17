import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import '../../../auth/presentation/pages/forgot_password_page.dart';

/// SecurityLoginPage
/// ----------------------------------------------------------------------
/// Menampilkan informasi metode login, provider otentikasi (Email/Google/Apple),
/// status enkripsi token sesi, dan aksi ganti kata sandi bila relevan.
/// ----------------------------------------------------------------------
class SecurityLoginPage extends StatelessWidget {
  final AuthUserEntity user;

  const SecurityLoginPage({super.key, required this.user});

  String get _providerLabel {
    final provider = user.authProvider?.toLowerCase() ?? '';
    if (provider.contains('google') || user.email.endsWith('@gmail.com') || user.id.contains('google')) {
      return 'Google Sign-In';
    }
    if (provider.contains('apple') || user.email.contains('appleid.com') || user.id.contains('apple')) {
      return 'Sign in with Apple';
    }
    return 'Email & Kata Sandi';
  }

  bool get _isThirdPartySso {
    final p = _providerLabel;
    return p == 'Google Sign-In' || p == 'Sign in with Apple';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Keamanan & Login'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. METODE LOGIN
              _buildSectionTitle('METODE OTENTIKASI'),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _buildSecurityRow(
                      icon: Icons.vpn_key_outlined,
                      title: 'Metode Masuk',
                      value: _providerLabel,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSecurityRow(
                      icon: Icons.verified_user_outlined,
                      title: 'ID Akun Terdaftar',
                      value: user.email,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSecurityRow(
                      icon: Icons.lock_outline,
                      title: 'Penyimpanan Kredensial',
                      value: 'Terenkripsi (Secure Storage)',
                      valueColor: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. KATA SANDI / SSO INFO
              _buildSectionTitle('MANAJEMEN KATA SANDI'),
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: _cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isThirdPartySso) ...[
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.action, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Masuk via $_providerLabel',
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Akun Anda terhubung dengan $_providerLabel. Pengaturan kata sandi dan autentikasi dua faktor dikelola langsung melalui penyedia akun Anda.',
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(Icons.password_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kata Sandi Akun',
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Ganti kata sandi secara berkala untuk menjaga keamanan.',
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.lock_reset, size: 18),
                          label: const Text('Reset / Ganti Kata Sandi'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.button),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. KEAMANAN PERANGKAT
              _buildSectionTitle('KEAMANAN PERANGKAT LAPANGAN'),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _buildSecurityRow(
                      icon: Icons.shield_outlined,
                      title: 'Validasi Integritas Foto',
                      value: 'SHA-256 Checksum',
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSecurityRow(
                      icon: Icons.gps_fixed_rounded,
                      title: 'Proteksi Lokasi Lapangan',
                      value: 'Anti-Mock GPS Aktif',
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildSecurityRow(
                      icon: Icons.devices_rounded,
                      title: 'Deteksi Root / Jailbreak',
                      value: 'Proteksi On-Device',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.sectionLabel.copyWith(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.cardLarge),
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadowSoft,
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
      border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
    );
  }

  Widget _buildSecurityRow({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.iconSoftBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.small.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
