import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';
import 'edit_profile_page.dart';

/// ProfileInfoPage
/// ----------------------------------------------------------------------
/// Menampilkan rincian lengkap identitas profil, instansi, NIP,
/// nomor telepon, serta peran otentikasi akun.
/// ----------------------------------------------------------------------
class ProfileInfoPage extends StatefulWidget {
  final AuthUserEntity user;

  const ProfileInfoPage({super.key, required this.user});

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  late AuthUserEntity _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  String _formatRole(String role) {
    switch (role) {
      case 'PEGAWAI':
        return 'Pegawai Lapangan';
      case 'VERIFIKATOR':
        return 'Verifikator';
      case 'ADMIN':
        return 'Administrator';
      case 'SUPER_ADMIN':
        return 'Super Admin';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final instansi = (_user.instansiName != null && _user.instansiName!.trim().isNotEmpty)
        ? _user.instansiName!.trim()
        : 'BPKAD Kabupaten Mimika';
    final nip = (_user.nip != null && _user.nip!.trim().isNotEmpty)
        ? _user.nip!.trim()
        : 'Belum diisi';
    final phone = (_user.phoneNumber != null && _user.phoneNumber!.trim().isNotEmpty)
        ? _user.phoneNumber!.trim()
        : 'Belum diisi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Informasi Profil'),
        centerTitle: true,
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            tooltip: 'Edit Profil',
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(user: _user),
                ),
              );
              if (updated == true && mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DATA PRIBADI CARD
              _buildSectionTitle('DATA PRIBADI'),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.person_outline,
                      label: 'Nama Lengkap',
                      value: _user.fullName.isNotEmpty ? _user.fullName : 'Leo Tiberius',
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildInfoTile(
                      icon: Icons.email_outlined,
                      label: 'Email Terdaftar',
                      value: _user.email,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildInfoTile(
                      icon: Icons.badge_outlined,
                      label: 'NIP Pegawai',
                      value: nip,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      label: 'Nomor Telepon',
                      value: phone,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. DATA PENUGASAN & INSTANSI CARD
              _buildSectionTitle('INSTANSI & PENUGASAN'),
              Container(
                decoration: _cardDecoration(),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.apartment_outlined,
                      label: 'Instansi',
                      value: instansi,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildInfoTile(
                      icon: Icons.shield_outlined,
                      label: 'Peran Akun',
                      value: _formatRole(_user.role),
                      valueColor: AppColors.primary,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildInfoTile(
                      icon: Icons.verified_user_outlined,
                      label: 'Status Akun',
                      value: 'Aktif & Terverifikasi',
                      valueColor: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. EDIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => EditProfilePage(user: _user),
                      ),
                    );
                    if (updated == true && mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Ubah Informasi Profil'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
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

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
            flex: 2,
            child: Text(
              label,
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
