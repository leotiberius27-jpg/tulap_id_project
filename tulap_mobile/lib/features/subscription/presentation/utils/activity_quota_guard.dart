import 'package:flutter/material.dart';
import '../../../../app/di/injection_container.dart';
import '../../domain/usecases/check_activity_quota.dart';
import '../widgets/quota_reached_sheet.dart';

/// ensureActivityQuotaAvailable
/// ----------------------------------------------------------------------
/// Dipanggil SEBELUM membuka layar "Buat Kegiatan" (Bagian 30 dokumen
/// redesign - SANGAT PENTING). Mengembalikan `true` jika user boleh
/// lanjut membuat kegiatan baru. Jika kuota sudah habis, menampilkan
/// QuotaReachedSheet dan mengembalikan `false` - TIDAK PERNAH memblokir
/// akses ke kegiatan yang sudah ada, hanya pembuatan kegiatan baru.
///
/// Kegagalan mengambil status kuota (mis. offline) SENGAJA fail-open
/// (tetap mengizinkan) - jangan sampai gangguan teknis kecil menahan
/// pekerjaan lapangan user yang sudah mendesak.
/// ----------------------------------------------------------------------
Future<bool> ensureActivityQuotaAvailable(BuildContext context) async {
  final result = await sl<CheckActivityQuota>()();

  final isAtLimit = result.fold((_) => false, (usage) => usage.isAtLimit);
  if (!isAtLimit) return true;

  if (!context.mounted) return false;
  await QuotaReachedSheet.show(context);
  return false;
}
