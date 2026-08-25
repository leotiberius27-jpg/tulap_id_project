import 'package:intl/intl.dart';

/// AppDateFormatter
/// ----------------------------------------------------------------------
/// Utilitas terpusat untuk pemformatan tanggal dan waktu kegiatan Tulap.id.
/// Memastikan:
/// 1. Format resmi Bahasa Indonesia (contoh: "25 Agustus 2026", "25 Agu 2026").
/// 2. Dukungan rentang multi-hari (contoh: "25–28 Agu 2026", "30 Agu – 2 Sep 2026").
/// 3. Tidak ada kebocoran format mentah DateTime (seperti 2026-08-25 21:03:44.123456).
/// 4. Menggunakan zona waktu lokal perangkat/pengguna tanpa hardcode global.
/// ----------------------------------------------------------------------
class AppDateFormatter {
  AppDateFormatter._();

  static const List<String> _monthsFull = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _monthsShort = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Format lengkap: "25 Agustus 2026"
  static String formatFull(DateTime date) {
    final d = date.toLocal();
    final monthName = (d.month >= 1 && d.month <= 12)
        ? _monthsFull[d.month]
        : '';
    return '${d.day} $monthName ${d.year}';
  }

  /// Format ringkas: "25 Agu 2026"
  static String formatCompact(DateTime date) {
    final d = date.toLocal();
    final monthName = (d.month >= 1 && d.month <= 12)
        ? _monthsShort[d.month]
        : '';
    return '${d.day} $monthName ${d.year}';
  }

  /// Format waktu jam:menit: "21:03"
  static String formatTime(DateTime date) {
    final d = date.toLocal();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Format tanggal + jam: "25 Agu 2026 • 21:03"
  static String formatDateTime(DateTime date) {
    return '${formatCompact(date)} • ${formatTime(date)}';
  }

  /// Format tanggal + jam lengkap: "25 Agustus 2026, 21:03"
  static String formatFullDateTime(DateTime date) {
    return '${formatFull(date)}, ${formatTime(date)}';
  }

  /// Format rentang tanggal kegiatan (single-day & multi-day)
  /// - Hari sama: "25 Agu 2026" (atau "25 Agu 2026 • 21:03" jika ada jam spesifik)
  /// - Bulan & Tahun sama: "25–28 Agu 2026" (atau "25 s.d. 28 Agustus 2026" jika full)
  /// - Bulan beda, Tahun sama: "30 Agu – 2 Sep 2026" (atau "30 Agustus s.d. 2 September 2026")
  /// - Tahun beda: "30 Des 2026 – 2 Jan 2027" (atau "30 Desember 2026 s.d. 2 Januari 2027")
  static String formatDateRange(
    DateTime start,
    DateTime end, {
    bool isFull = false,
    bool showTimeIfSameDay = false,
  }) {
    final s = start.toLocal();
    final e = end.toLocal();

    final months = isFull ? _monthsFull : _monthsShort;
    final separator = isFull ? ' s.d. ' : ' – ';
    final rangeDash = isFull ? ' s.d. ' : '–';

    final sMonth = (s.month >= 1 && s.month <= 12) ? months[s.month] : '';
    final eMonth = (e.month >= 1 && e.month <= 12) ? months[e.month] : '';

    // Hari yang sama
    if (s.year == e.year && s.month == e.month && s.day == e.day) {
      if (showTimeIfSameDay && (s.hour != 0 || s.minute != 0)) {
        return '${s.day} $sMonth ${s.year} • ${formatTime(s)}';
      }
      return '${s.day} $sMonth ${s.year}';
    }

    // Bulan dan Tahun sama (Multi-hari dalam 1 bulan)
    if (s.year == e.year && s.month == e.month) {
      return '${s.day}$rangeDash${e.day} $sMonth ${s.year}';
    }

    // Tahun sama, Bulan beda (Lintas bulan)
    if (s.year == e.year) {
      return '${s.day} $sMonth$separator${e.day} $eMonth ${s.year}';
    }

    // Tahun beda (Lintas tahun)
    return '${s.day} $sMonth ${s.year}$separator${e.day} $eMonth ${e.year}';
  }

  /// Format mata uang Rupiah: "Rp250.000"
  static String formatRupiah(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
