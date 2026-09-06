import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// TulaInsightBubble
/// ----------------------------------------------------------------------
/// Mini contextual bubble yang muncul sesekali di samping Tula untuk
/// informasi singkat (maks 1-2 baris, Bagian 14-15 spesifikasi upgrade
/// Tula draggable) - mis. "1 bukti belum lengkap". TulaOverlay yang
/// mengatur kapan bubble ini dipasang & auto-dismiss-nya; widget ini
/// murni presentasi + tap handler.
/// ----------------------------------------------------------------------
class TulaInsightBubble extends StatelessWidget {
  final String message;

  /// true jika Tula berada di sisi kiri layar - bubble mengikuti sisi
  /// yang sama supaya tidak keluar layar.
  final bool anchorLeft;
  final VoidCallback onTap;

  const TulaInsightBubble({
    super.key,
    required this.message,
    required this.anchorLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadowSoft,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: anchorLeft ? TextAlign.left : TextAlign.right,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
