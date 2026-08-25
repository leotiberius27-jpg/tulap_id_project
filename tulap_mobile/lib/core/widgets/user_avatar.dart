import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// UserAvatar
/// ----------------------------------------------------------------------
/// Komponen avatar terstandarisasi untuk seluruh aplikasi Tulap.id:
/// Digunakan oleh HomeHeader, ProfileHeaderCard, EditProfilePage, dan
/// komponen profil lainnya.
///
/// Mendukung:
/// 1. Remote URL (`https://` atau `http://`)
/// 2. Local File path (`/data/...`, `file:///...`, `content://...`)
/// 3. Inisial Nama Resmi (fallback 2 huruf: 'Leo Tiberius' -> 'LT')
/// 4. Graceful Error Handling & Fallback otomatis
/// ----------------------------------------------------------------------
class UserAvatar extends StatelessWidget {
  final String fullName;
  final String? photoUrl;
  final double size;
  final VoidCallback? onTap;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final Color? backgroundColor;
  final double? fontSize;
  final String? semanticsLabel;

  const UserAvatar({
    super.key,
    required this.fullName,
    this.photoUrl,
    this.size = 42.0,
    this.onTap,
    this.border,
    this.boxShadow,
    this.gradient,
    this.backgroundColor,
    this.fontSize,
    this.semanticsLabel,
  });

  /// Menghitung inisial 2 huruf dari nama lengkap
  static String computeInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'U';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      final single = parts.first;
      return single.length >= 2
          ? single.substring(0, 2).toUpperCase()
          : single[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = computeInitials(fullName);
    final calculatedFontSize = fontSize ?? (size * 0.38).clamp(10.0, 32.0);

    final avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.primary,
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
            ),
        border: border ?? Border.all(color: Colors.white, width: size > 60 ? 2.5 : 2.0),
        boxShadow: boxShadow ??
            const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
      ),
      child: ClipOval(
        child: _buildImageOrFallback(initials, calculatedFontSize),
      ),
    );

    final label = semanticsLabel ?? 'Avatar $fullName';

    if (onTap != null) {
      return Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: avatarWidget,
        ),
      );
    }

    return Semantics(
      label: label,
      child: avatarWidget,
    );
  }

  Widget _buildImageOrFallback(String initials, double calculatedFontSize) {
    if (photoUrl == null || photoUrl!.trim().isEmpty) {
      return _buildInitials(initials, calculatedFontSize);
    }

    final rawPath = photoUrl!.trim();

    // 1. Remote Image (HTTPS / HTTP)
    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return Image.network(
        rawPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitials(initials, calculatedFontSize),
      );
    }

    // 2. Local File Path (file:// atau absolute path)
    try {
      final sanitizedPath = rawPath.startsWith('file://')
          ? rawPath.replaceFirst('file://', '')
          : rawPath;
      final file = File(sanitizedPath);

      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitials(initials, calculatedFontSize),
        );
      }
    } catch (_) {
      // Fallback jika permission atau path error
    }

    // 3. Fallback ke Initials
    return _buildInitials(initials, calculatedFontSize);
  }

  Widget _buildInitials(String initials, double calculatedFontSize) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: calculatedFontSize,
          letterSpacing: size > 60 ? 1.0 : 0.0,
        ),
      ),
    );
  }
}
