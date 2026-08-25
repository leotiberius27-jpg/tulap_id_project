import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/auth_user_entity.dart';

/// ProfileHeaderCard
/// ----------------------------------------------------------------------
/// Menampilkan identitas resmi pengguna di bagian atas halaman Akun:
/// Avatar dinamis (Foto -> Inisial), Nama lengkap, Email, Instansi/Role,
/// dan tombol "Edit Profil".
/// ----------------------------------------------------------------------
class ProfileHeaderCard extends StatelessWidget {
  final AuthUserEntity user;
  final VoidCallback onEditProfile;

  const ProfileHeaderCard({
    super.key,
    required this.user,
    required this.onEditProfile,
  });

  static String getInitials(String fullName) {
    return UserAvatar.computeInitials(fullName);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final instansi = (user.instansiName != null && user.instansiName!.trim().isNotEmpty)
        ? user.instansiName!.trim()
        : 'BPKAD Kabupaten Mimika';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg + 4,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        boxShadow: [
          BoxShadow(
            color: colors.shadowSoft,
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. AVATAR DINAMIS
          UserAvatar(
            fullName: user.fullName,
            photoUrl: user.photoUrl,
            size: 84,
            border: Border.all(color: colors.surface, width: 3),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. NAMA LENGKAP
          Text(
            user.fullName.isNotEmpty ? user.fullName : 'Leo Tiberius',
            style: AppTypography.pageTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // 3. EMAIL
          Text(
            user.email,
            style: AppTypography.body.copyWith(
              fontSize: 14,
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // 4. INSTANSI / ORGANISASI
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: colors.iconSoftBlue,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              instansi,
              style: AppTypography.small.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 5. TOMBOL EDIT PROFIL
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: onEditProfile,
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: colors.primary,
              ),
              label: Text(
                'Edit Profil',
                style: AppTypography.body.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                backgroundColor: colors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
