import 'package:flutter/material.dart';
import '../../../../core/geo/fast_location_service.dart';
import '../../domain/usecases/validate_location_integrity.dart';

/// GpsStatusIndicator
/// ----------------------------------------------------------------------
/// Badge status GPS real-time di top bar kamera sesuai spesifikasi:
///   🟢 <= 15 m -> "GPS Akurat • ±Xm"
///   🔵 16–30 m -> "GPS Cukup • ±Xm"
///   🟠 Fast Initial -> "Lokasi Sementara • ±Xm"
///   🔴 >50 m   -> "GPS Lemah • ±Xm"
///   🟡 Check   -> "Menyiapkan GPS..."
/// ----------------------------------------------------------------------
class GpsStatusIndicator extends StatelessWidget {
  final LocationIntegrityStatus status;
  final LocationTier tier;
  final double? accuracyMeters;

  const GpsStatusIndicator({
    super.key,
    required this.status,
    this.tier = LocationTier.none,
    this.accuracyMeters,
  });

  @override
  Widget build(BuildContext context) {
    final config = _resolveConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: config.borderColor, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: config.foreground),
          const SizedBox(width: 6),
          Icon(config.icon, size: 14, color: config.foreground),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(
              color: config.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _GpsDisplayConfig _resolveConfig() {
    if (status == LocationIntegrityStatus.invalid ||
        tier == LocationTier.mocked) {
      final acc = accuracyMeters != null
          ? ' • ±${accuracyMeters!.round()}m'
          : '';
      return _GpsDisplayConfig(
        label: 'Lokasi Tidak Valid$acc',
        icon: Icons.error_outline_rounded,
        foreground: const Color(0xFFEF4444),
        textColor: Colors.white,
        background: const Color(0xB33F1313),
        borderColor: const Color(0x60EF4444),
      );
    }

    if (tier == LocationTier.fastInitial && accuracyMeters != null) {
      return _GpsDisplayConfig(
        label: 'Lokasi Sementara • ±${accuracyMeters!.round()}m',
        icon: Icons.location_on_outlined,
        foreground: const Color(0xFF38BDF8),
        textColor: Colors.white,
        background: const Color(0xB30C2847),
        borderColor: const Color(0x6038BDF8),
      );
    }

    if (status == LocationIntegrityStatus.checking ||
        tier == LocationTier.none) {
      return _GpsDisplayConfig(
        label: 'Menyiapkan GPS...',
        icon: Icons.gps_not_fixed_rounded,
        foreground: const Color(0xFFF59E0B),
        textColor: Colors.white,
        background: const Color(0xB31E293B),
        borderColor: const Color(0x40F59E0B),
      );
    }

    // Status Valid -> bedakan berdasarkan rentang akurasi
    final acc = accuracyMeters;
    if (acc == null) {
      return _GpsDisplayConfig(
        label: 'Lokasi Valid',
        icon: Icons.check_circle_outline_rounded,
        foreground: const Color(0xFF10B981),
        textColor: Colors.white,
        background: const Color(0xB30F2A1D),
        borderColor: const Color(0x5010B981),
      );
    }

    if (acc <= 15) {
      return _GpsDisplayConfig(
        label: 'GPS Akurat • ±${acc.round()}m',
        icon: Icons.verified_rounded,
        foreground: const Color(0xFF10B981), // Green
        textColor: Colors.white,
        background: const Color(0xB30B301E),
        borderColor: const Color(0x7010B981),
      );
    } else if (acc <= 30) {
      return _GpsDisplayConfig(
        label: 'GPS Cukup • ±${acc.round()}m',
        icon: Icons.check_circle_rounded,
        foreground: const Color(0xFF38BDF8), // Blue
        textColor: Colors.white,
        background: const Color(0xB30C2847),
        borderColor: const Color(0x6038BDF8),
      );
    } else if (acc <= 50) {
      return _GpsDisplayConfig(
        label: 'Mengunci Lokasi • ±${acc.round()}m',
        icon: Icons.info_outline_rounded,
        foreground: const Color(0xFFFB923C), // Amber/Orange
        textColor: Colors.white,
        background: const Color(0xB33A1F0D),
        borderColor: const Color(0x60FB923C),
      );
    } else {
      return _GpsDisplayConfig(
        label: 'GPS Lemah • ±${acc.round()}m',
        icon: Icons.warning_amber_rounded,
        foreground: const Color(0xFFEF4444), // Red
        textColor: Colors.white,
        background: const Color(0xB33F1313),
        borderColor: const Color(0x60EF4444),
      );
    }
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.8,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GpsDisplayConfig {
  final String label;
  final IconData icon;
  final Color foreground;
  final Color textColor;
  final Color background;
  final Color borderColor;

  _GpsDisplayConfig({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.textColor,
    required this.background,
    required this.borderColor,
  });
}
