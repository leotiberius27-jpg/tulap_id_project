import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/plan_entity.dart';
import '../utils/plan_visuals.dart';
import 'plan_folder_shape.dart';

/// PlanFolderShell
/// ----------------------------------------------------------------------
/// Struktur visual folder LENGKAP (Bagian 3 dokumen redesign):
/// 1. Tab (kiri-atas, berisi kode paket - "PRO")
/// 2. Shoulder (transisi halus tab -> body)
/// 3. Body (badan folder berwarna)
/// 4. Lip (strip di bawah tab, berisi nama paket + badge)
/// 5. Inner content sheet putih (di dalam folder, bukan ditempel)
/// 6. Depth (shadow mengikuti siluet folder)
/// ----------------------------------------------------------------------
class PlanFolderShell extends StatelessWidget {
  final PlanEntity plan;
  final PlanFolderPalette palette;
  final double elevation;
  final double lipSettle;
  final double sheetParallaxDx;
  final Widget sheetContent;

  static const double tabWidthFraction = 0.42;
  static const double tabHeight = 46;
  static const double lipHeight = 54;
  static const double cornerRadius = 22;

  const PlanFolderShell({
    super.key,
    required this.plan,
    required this.palette,
    required this.elevation,
    required this.lipSettle,
    required this.sheetParallaxDx,
    required this.sheetContent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            // 6. Depth - shadow yang mengikuti siluet folder persis.
            CustomPaint(
              size: size,
              painter: FolderShadowPainter(
                tabWidthFraction: tabWidthFraction,
                tabHeight: tabHeight,
                cornerRadius: cornerRadius,
                elevation: elevation,
              ),
            ),
            // 1-4. Tab + shoulder + body + lip - satu bentuk folder utuh.
            ClipPath(
              clipper: const FolderClipper(
                tabWidthFraction: tabWidthFraction,
                tabHeight: tabHeight,
                cornerRadius: cornerRadius,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: palette.gradient),
              ),
            ),
            // Label kode paket di tab ("PRO").
            Positioned(
              left: 18,
              top: 0,
              height: tabHeight,
              width: size.width * tabWidthFraction - 18,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  plan.tabLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: palette.onFolder,
                  ),
                ),
              ),
            ),
            // Lip: nama paket lengkap + badge (settle animation halus).
            Positioned(
              left: 20,
              right: 20,
              top: tabHeight,
              height: lipHeight,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                opacity: lipSettle,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  offset: Offset(0, (1 - lipSettle) * 0.08),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          plan.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: palette.onFolder,
                          ),
                        ),
                      ),
                      if (plan.badgeLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            plan.badgeLabel!,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: palette.onFolder,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // 5. Inner content sheet - INSET di dalam folder (bukan
            // menempel di tepi), memberi ilusi "di dalam wadah" + sedikit
            // parallax subtle saat drag.
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              top: tabHeight + lipHeight,
              child: Transform.translate(
                offset: Offset(sheetParallaxDx, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                      bottom: Radius.circular(cornerRadius - 6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                      bottom: Radius.circular(cornerRadius - 6),
                    ),
                    child: sheetContent,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
