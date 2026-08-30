class ActivityTrendPoint {
  final String date;
  final String label;
  final int count;

  const ActivityTrendPoint({
    required this.date,
    required this.label,
    required this.count,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityTrendPoint &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          label == other.label &&
          count == other.count;

  @override
  int get hashCode => Object.hash(date, label, count);
}
