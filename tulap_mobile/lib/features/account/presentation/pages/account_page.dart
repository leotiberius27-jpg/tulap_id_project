import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../auth/domain/usecases/logout.dart';
import '../controllers/account_controller.dart';

/// AccountPage (Akun)
/// ----------------------------------------------------------------------
/// Tab "Akun" di bottom navigation - identitas pegawai yang sedang
/// login (data asli dari sesi tersimpan, sama seperti yang dipakai
/// Beranda) dan tombol Keluar yang benar-benar berfungsi.
/// ----------------------------------------------------------------------
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AccountController>(
      create: (_) => AccountController(
        getCurrentSession: sl<GetCurrentSession>(),
        logout: sl<Logout>(),
      ),
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Akun')),
      body: SafeArea(
        top: false,
        // Padding bawah tetap agar tombol kamera tengah (FAB centerDocked
        // di MainShell) tidak menutupi konten terakhir - lihat catatan
        // yang sama di HomePage.
        child: Padding(
          padding: const EdgeInsets.only(bottom: 56),
          child: Consumer<AccountController>(
          builder: (context, controller, _) {
            final user = controller.state.user;
            if (user == null) {
              return const AppLoadingView(label: 'Memuat akun...');
            }

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.base),
              children: [
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
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.iconSoftBlue,
                        child: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : '?',
                          style: AppTypography.pageTitle.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        user.fullName,
                        style: AppTypography.sectionTitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.iconSoftBlue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _roleLabel(user.role),
                          style: AppTypography.small.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.md),
                      _InfoRow(
                        icon: Icons.apartment_outlined,
                        label: 'Instansi',
                        value: user.instansiName ?? 'Tidak diketahui',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        value: user.email,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: controller.state.isLoggingOut
                      ? null
                      : () => _confirmLogout(context, controller),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.dangerSoft, width: 1.5),
                  ),
                  icon: controller.state.isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('Keluar'),
                ),
              ],
            );
          },
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'PEGAWAI':
        return 'Pegawai';
      case 'VERIFIKATOR':
        return 'Verifikator';
      case 'ADMIN':
        return 'Admin';
      case 'SUPER_ADMIN':
        return 'Super Admin';
      default:
        return role;
    }
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AccountController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda perlu masuk kembali dengan email dan password untuk '
          'melanjutkan tugas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await controller.signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.small),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTypography.small.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
