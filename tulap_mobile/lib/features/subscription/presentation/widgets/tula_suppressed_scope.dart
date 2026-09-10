import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../../assistant/presentation/controllers/tula_visibility_controller.dart';

/// TulaSuppressedScope
/// ----------------------------------------------------------------------
/// Menyembunyikan floating Tula total selama layar pembayaran aktif
/// (Bagian 51 instruksi payment - Tula tidak boleh menutupi QR, VA,
/// amount, atau CTA pada layar checkout kritikal). Pola identik dengan
/// sesi kamera fullscreen (lihat GeotagCameraEntryPage/
/// ReceiptScannerEntryPage) - `suppress()` di initState, `unsuppress()`
/// di dispose lewat TulaVisibilityController yang sama.
/// ----------------------------------------------------------------------
class TulaSuppressedScope extends StatefulWidget {
  final Widget child;
  const TulaSuppressedScope({super.key, required this.child});

  @override
  State<TulaSuppressedScope> createState() => _TulaSuppressedScopeState();
}

class _TulaSuppressedScopeState extends State<TulaSuppressedScope> {
  late final TulaVisibilityController _tula;

  @override
  void initState() {
    super.initState();
    _tula = sl<TulaVisibilityController>();
    _tula.suppress();
  }

  @override
  void dispose() {
    _tula.unsuppress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
