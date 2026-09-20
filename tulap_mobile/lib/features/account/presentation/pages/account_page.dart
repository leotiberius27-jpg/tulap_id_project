import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../../../core/sync/background_sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../main.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../auth/domain/usecases/logout.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../../sync_queue/presentation/pages/sync_center_page.dart';
import '../../../subscription/presentation/pages/payment_history_page.dart';
import '../../../subscription/presentation/pages/subscription_page.dart';
import '../../domain/usecases/clear_app_cache.dart';
import '../../domain/usecases/get_storage_breakdown.dart';
import '../controllers/account_controller.dart';
import '../widgets/account_menu_row.dart';
import '../widgets/account_section_card.dart';
import '../widgets/logout_protection_dialog.dart';
import '../widgets/profile_header_card.dart';
import '../../../../core/localization/language_controller.dart';
import 'about_tulap_page.dart';
import 'camera_settings_page.dart';
import 'device_storage_page.dart';
import 'edit_profile_page.dart';
import 'help_support_page.dart';
import 'language_settings_page.dart';
import 'location_settings_page.dart';
import 'notification_settings_page.dart';
import 'privacy_page.dart';
import 'profile_info_page.dart';
import 'security_login_page.dart';
import 'terms_page.dart';

/// AccountPage (Akun & Profil Tulap.id)
/// ----------------------------------------------------------------------
/// Modul Akun & Profil Lapangan Resmi Tulap.id:
/// 1. ProfileHeader (Avatar Dinamis, Nama, Email, Instansi, Edit Profil)
/// 2. Section 1: Akun & Keamanan (Info Profil, Keamanan & Login)
/// 3. Section 2: Data & Sinkronisasi (Status Outbox, Storage, Cache Aman)
/// 4. Section 3: Pengaturan (Notifikasi, Kamera Geotag, Lokasi GPS, Bahasa)
/// 5. Section 4: Bantuan & Informasi (Panduan Lapangan, Privasi, Syarat, Tentang)
/// 6. Logout Section (Dengan proteksi antrian data outbox belum tersinkron)
/// ----------------------------------------------------------------------
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AccountController>(
      create: (_) => AccountController(
        getCurrentSession: sl<GetCurrentSession>(),
        logout: sl<Logout>(),
        syncQueueRepository: sl<SyncQueueRepository>(),
        backgroundSyncService: sl<BackgroundSyncService>(),
        getStorageBreakdown: sl<GetStorageBreakdown>(),
        clearAppCache: sl<ClearAppCache>(),
        authSessionManager: sl<AuthSessionManager>(),
      ),
      child: const _AccountView(),
    );
  }
}

class _AccountView extends StatelessWidget {
  const _AccountView();

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Akun'),
        centerTitle: true,
        backgroundColor: colors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Consumer<AccountController>(
          builder: (context, controller, _) {
            final user = controller.state.user;
            if (user == null) {
              return const AppLoadingView(label: 'Memuat akun...');
            }

            return RefreshIndicator(
              onRefresh: () => controller.refresh(),
              color: colors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.base,
                  84, // Bottom padding aman dari FAB Kamera tengah
                ),
                children: [
                  // ============================================================
                  // 1. PROFILE HEADER CARD
                  // ============================================================
                  ProfileHeaderCard(
                    user: user,
                    onEditProfile: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(user: user),
                        ),
                      );
                      if (updated == true) {
                        controller.refresh();
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ============================================================
                  // 1B. SECTION — PAKET & LANGGANAN (Redesign folder carousel)
                  // ============================================================
                  AccountSectionCard(
                    title: 'PAKET & LANGGANAN',
                    children: [
                      AccountMenuRow(
                        icon: Icons.folder_special_outlined,
                        iconBgColor: AppColors.iconSoftBlue,
                        title: 'Paket Tulap',
                        subtitle: 'Lihat & kelola paket kegiatan bulanan Anda',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionPage(),
                          ),
                        ),
                      ),
                      AccountMenuRow(
                        icon: Icons.receipt_long_outlined,
                        iconBgColor: AppColors.iconSoftTeal,
                        title: 'Riwayat Pembayaran',
                        subtitle: 'Transaksi QRIS/VA paket Tulap Anda',
                        showDivider: false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PaymentHistoryPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ============================================================
                  // 2. SECTION 1 — AKUN & KEAMANAN
                  // ============================================================
                  AccountSectionCard(
                    title: 'AKUN & KEAMANAN',
                    children: [
                      AccountMenuRow(
                        icon: Icons.person_outline,
                        iconBgColor: AppColors.iconSoftBlue,
                        title: 'Informasi Profil',
                        subtitle:
                            'Rincian identitas, NIP, & instansi penugasan',
                        onTap: () async {
                          final updated = await Navigator.of(context)
                              .push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => ProfileInfoPage(user: user),
                                ),
                              );
                          if (updated == true) {
                            controller.refresh();
                          }
                        },
                      ),
                      AccountMenuRow(
                        icon: Icons.lock_outline,
                        iconBgColor: AppColors.iconSoftIndigo,
                        title: 'Keamanan & Login',
                        subtitle: 'Metode otentikasi & proteksi kredensial',
                        showDivider: false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SecurityLoginPage(user: user),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ============================================================
                  // 3. SECTION 2 — DATA & SINKRONISASI
                  // ============================================================
                  AccountSectionCard(
                    title: 'DATA & SINKRONISASI',
                    children: [
                      AccountMenuRow(
                        icon: Icons.cloud_sync_outlined,
                        iconBgColor: AppColors.iconSoftBlue,
                        title: 'Status Sinkronisasi',
                        subtitle: controller.state.syncStatusSubtitle,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (controller.state.isSyncing)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            else if (controller.state.failedSyncCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${controller.state.failedSyncCount}',
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              )
                            else if (controller.state.pendingSyncCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warningSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${controller.state.pendingSyncCount}',
                                  style: AppTypography.small.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              )
                            else
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.success,
                                size: 18,
                              ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SyncCenterPage(),
                            ),
                          );
                          if (context.mounted) {
                            controller.refresh();
                          }
                        },
                      ),
                      AccountMenuRow(
                        icon: Icons.storage_outlined,
                        iconBgColor: AppColors.iconSoftTeal,
                        title: 'Penyimpanan Perangkat',
                        subtitle: controller.state.storageBreakdown != null
                            ? 'Tulap.id: ${controller.state.storageBreakdown!.formattedTotal}'
                            : 'Memuat status memori...',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DeviceStoragePage(),
                          ),
                        ),
                      ),
                      AccountMenuRow(
                        icon: Icons.delete_sweep_outlined,
                        iconBgColor: AppColors.iconSoftCyan,
                        title: 'Data & Cache',
                        subtitle: 'Bersihkan file sementara secara aman',
                        showDivider: false,
                        onTap: () => _confirmClearCache(context, controller),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ============================================================
                  // 4. SECTION 3 — PENGATURAN
                  // ============================================================
                  AccountSectionCard(
                    title: 'PENGATURAN',
                    children: [
                      AccountMenuRow(
                        icon: Icons.notifications_none_rounded,
                        iconBgColor: AppColors.iconSoftBlue,
                        title: 'Notifikasi',
                        subtitle: 'Pengingat tugas & status sinkronisasi',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsPage(),
                          ),
                        ),
                      ),
                      AccountMenuRow(
                        icon: Icons.camera_alt_outlined,
                        iconBgColor: AppColors.iconSoftIndigo,
                        title: 'Kamera & Dokumentasi',
                        subtitle: 'Preferensi watermark & standar integritas',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CameraSettingsPage(),
                          ),
                        ),
                      ),
                      AccountMenuRow(
                        icon: Icons.location_on_outlined,
                        iconBgColor: AppColors.iconSoftTeal,
                        title: 'Lokasi & GPS',
                        subtitle: 'Izin GPS & kebijakan privasi lapangan',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LocationSettingsPage(),
                          ),
                        ),
                      ),
                      AccountMenuRow(
                        icon: Icons.language_rounded,
                        iconBgColor: AppColors.iconSoftBlue,
                        title: 'Bahasa / Language',
                        subtitle:
                            sl<LanguageController>().currentLanguage.label,
                        showDivider: false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LanguageSettingsPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ============================================================
                  // 5. SECTION 4 — BANTUAN & INFORMASI
                  // ============================================================
                  AccountSectionCard(
                    title: 'BANTUAN & INFORMASI',
                    children: [
                      AccountMenuRow(
                        icon: Icons.help_outline_rounded,
                        iconBgColor: AppColors.iconSoftBlue,
                        title: 'Bantuan & Dukungan',
                        subtitle: 'Panduan kamera, GPS, tugas, dan nota',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpSupportPage(),
                          ),
                        ),
                      ),
                      AccountMenuRow(
                        icon: Icons.privacy_tip_outlined,
                        iconBgColor: AppColors.iconSoftIndigo,
                        title: 'Kebijakan Privasi',
                        subtitle: 'Perlindungan data & privasi sensor',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PrivacyPage(),
                          ),
                        ),
                      ),
                      AccountMenuRow(
                        icon: Icons.description_outlined,
                        iconBgColor: AppColors.iconSoftTeal,
                        title: 'Syarat Penggunaan',
                        subtitle: 'Aturan kepatuhan dokumentasi kegiatan',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TermsPage()),
                        ),
                      ),
                      AccountMenuRow(
                        icon: Icons.info_outline_rounded,
                        iconBgColor: AppColors.iconSoftCyan,
                        title: 'Tentang Tulap.id',
                        subtitle: 'Versi ${AboutTulapPage.appVersion}',
                        showDivider: false,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutTulapPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ============================================================
                  // 6. LOGOUT BUTTON
                  // ============================================================
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: controller.state.isLoggingOut
                          ? null
                          : () => _handleLogout(context, controller),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                      label: controller.state.isLoggingOut
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.danger,
                              ),
                            )
                          : const Text(
                              'Keluar dari Akun',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: AppColors.danger,
                          width: 1.2,
                        ),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmClearCache(
    BuildContext context,
    AccountController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        ),
        title: const Text('Bersihkan Cache?'),
        content: const Text(
          'File sementara akan dihapus. Seluruh bukti foto, nota, dan catatan kegiatan Anda TETAP AMAN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await controller.clearCache();
      if (context.mounted && controller.state.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.state.message!),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout(
    BuildContext context,
    AccountController controller,
  ) async {
    final action = await LogoutProtectionDialog.show(
      context,
      pendingCount: controller.state.pendingSyncCount,
    );

    if (action == null ||
        action == LogoutDialogAction.cancel ||
        !context.mounted) {
      return;
    }

    if (action == LogoutDialogAction.syncNow) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SyncCenterPage()));
      return;
    }

    if (action == LogoutDialogAction.logoutNow) {
      await controller.signOut();
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }
}
