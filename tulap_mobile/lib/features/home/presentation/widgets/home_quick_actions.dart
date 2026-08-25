import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

/// HomeQuickActions (Aksi Cepat)
/// ----------------------------------------------------------------------
/// Menampilkan 4 tombol aksi cepat: Foto, Nota, Lokasi, LPJ.
/// - Layar standar (>= 360dp): 4 kolom sejajar
/// - Layar kecil (< 360dp): 2x2 grid adaptif
/// - Touch target minimum 48x48dp
/// ----------------------------------------------------------------------
class HomeQuickActions extends StatelessWidget {
  final VoidCallback? onFoto;
  final VoidCallback? onNota;
  final VoidCallback? onLokasi;
  final VoidCallback? onLpj;

  const HomeQuickActions({
    super.key,
    this.onFoto,
    this.onNota,
    this.onLokasi,
    this.onLpj,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenWidth < 360;

    final items = [
      _ActionItem(
        label: 'Foto',
        icon: Icons.camera_alt_outlined,
        color: AppColors.primary,
        bgColor: AppColors.iconSoftBlue,
        onTap: onFoto,
      ),
      _ActionItem(
        label: 'Nota',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF0284C7),
        bgColor: AppColors.iconSoftCyan,
        onTap: onNota,
      ),
      _ActionItem(
        label: 'Lokasi',
        icon: Icons.place_outlined,
        color: const Color(0xFF0D9488),
        bgColor: AppColors.iconSoftTeal,
        onTap: onLokasi,
      ),
      _ActionItem(
        label: 'LPJ',
        icon: Icons.description_outlined,
        color: const Color(0xFF4F46E5),
        bgColor: AppColors.iconSoftIndigo,
        onTap: onLpj,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isSmallScreen)
            // 2x2 Grid untuk layar kecil (< 360dp)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.6,
              ),
              itemBuilder: (_, index) => _buildGridCard(items[index]),
            )
          else
            // 4 Kolom sejajar untuk layar standar & lebar
            Row(
              children: items
                  .map((item) => Expanded(child: _buildColumnButton(item)))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildColumnButton(_ActionItem item) {
    final isEnabled = item.onTap != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  HapticFeedback.selectionClick();
                  item.onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.45,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowSoft,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(_ActionItem item) {
    final isEnabled = item.onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                HapticFeedback.selectionClick();
                item.onTap!();
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onTap,
  });
}
