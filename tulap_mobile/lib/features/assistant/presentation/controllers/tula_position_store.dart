import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Posisi Tula yang dipersist - dinormalisasi (bukan pixel absolut) agar
/// tetap valid lintas ukuran layar/rotasi (Bagian 4 & 21 spesifikasi
/// upgrade Tula draggable).
class TulaPosition {
  final bool isLeft;

  /// 0.0 = paling atas area aman, 1.0 = paling bawah area aman.
  final double verticalRatio;

  const TulaPosition({required this.isLeft, required this.verticalRatio});

  TulaPosition clamped() =>
      TulaPosition(isLeft: isLeft, verticalRatio: verticalRatio.clamp(0.0, 1.0));
}

/// TulaPositionStore
/// ----------------------------------------------------------------------
/// Persistensi posisi floating Tula memakai FlutterSecureStorage yang
/// sudah dipakai project ini untuk preferensi ringan lain (lihat
/// AccountLocalDataSourceImpl - tema/bahasa) - tidak ada dependency baru.
/// ----------------------------------------------------------------------
class TulaPositionStore {
  static const _kSideKey = 'tula_position_side';
  static const _kRatioKey = 'tula_position_vratio';

  final FlutterSecureStorage _storage;

  const TulaPositionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<TulaPosition?> load() async {
    try {
      final side = await _storage.read(key: _kSideKey);
      final ratioStr = await _storage.read(key: _kRatioKey);
      if (side == null || ratioStr == null) return null;
      final ratio = double.tryParse(ratioStr);
      if (ratio == null) return null;
      return TulaPosition(isLeft: side == 'LEFT', verticalRatio: ratio).clamped();
    } catch (_) {
      return null;
    }
  }

  Future<void> save(TulaPosition position) async {
    try {
      await _storage.write(
        key: _kSideKey,
        value: position.isLeft ? 'LEFT' : 'RIGHT',
      );
      await _storage.write(
        key: _kRatioKey,
        value: position.verticalRatio.toStringAsFixed(4),
      );
    } catch (_) {
      // Gagal simpan posisi bukan error kritis - Tula tetap dipakai di
      // posisi berjalan, hanya tidak diingat sesi berikutnya.
    }
  }
}
