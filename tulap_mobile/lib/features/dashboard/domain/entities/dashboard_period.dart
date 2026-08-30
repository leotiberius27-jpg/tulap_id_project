enum DashboardPeriodType {
  today,
  sevenDays,
  thirtyDays,
  thisMonth,
  thisYear,
  custom,
}

class DashboardPeriod {
  final DashboardPeriodType type;
  final DateTime startDate;
  final DateTime endDate;
  final String label;

  const DashboardPeriod({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  static const List<String> _indoMonths = [
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

  /// Factory for "Hari Ini"
  factory DashboardPeriod.today({DateTime? now}) {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, n.day, 0, 0, 0);
    final end = DateTime(n.year, n.month, n.day, 23, 59, 59);
    return DashboardPeriod(
      type: DashboardPeriodType.today,
      startDate: start,
      endDate: end,
      label: 'Hari Ini',
    );
  }

  /// Factory for "7 Hari Terakhir"
  factory DashboardPeriod.sevenDays({DateTime? now}) {
    final n = now ?? DateTime.now();
    final start = n.subtract(const Duration(days: 6));
    final startDate = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final endDate = DateTime(n.year, n.month, n.day, 23, 59, 59);
    return DashboardPeriod(
      type: DashboardPeriodType.sevenDays,
      startDate: startDate,
      endDate: endDate,
      label: '7 Hari Terakhir',
    );
  }

  /// Factory for "30 Hari Terakhir"
  factory DashboardPeriod.thirtyDays({DateTime? now}) {
    final n = now ?? DateTime.now();
    final start = n.subtract(const Duration(days: 29));
    final startDate = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final endDate = DateTime(n.year, n.month, n.day, 23, 59, 59);
    return DashboardPeriod(
      type: DashboardPeriodType.thirtyDays,
      startDate: startDate,
      endDate: endDate,
      label: '30 Hari Terakhir',
    );
  }

  /// Factory for "Bulan Ini"
  factory DashboardPeriod.thisMonth({DateTime? now}) {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, 1, 0, 0, 0);
    final nextMonthFirst = (n.month == 12)
        ? DateTime(n.year + 1, 1, 1)
        : DateTime(n.year, n.month + 1, 1);
    final end = nextMonthFirst.subtract(const Duration(seconds: 1));

    final monthName = '${_indoMonths[n.month - 1]} ${n.year}';
    return DashboardPeriod(
      type: DashboardPeriodType.thisMonth,
      startDate: start,
      endDate: end,
      label: monthName,
    );
  }

  /// Factory for "Tahun Ini"
  factory DashboardPeriod.thisYear({DateTime? now}) {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, 1, 1, 0, 0, 0);
    final end = DateTime(n.year, 12, 31, 23, 59, 59);
    return DashboardPeriod(
      type: DashboardPeriodType.thisYear,
      startDate: start,
      endDate: end,
      label: 'Tahun ${n.year}',
    );
  }

  /// Factory for custom date range
  factory DashboardPeriod.custom({
    required DateTime start,
    required DateTime end,
    required String label,
  }) {
    final s = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return DashboardPeriod(
      type: DashboardPeriodType.custom,
      startDate: s,
      endDate: e,
      label: label,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardPeriod &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          label == other.label;

  @override
  int get hashCode => Object.hash(type, startDate, endDate, label);
}
