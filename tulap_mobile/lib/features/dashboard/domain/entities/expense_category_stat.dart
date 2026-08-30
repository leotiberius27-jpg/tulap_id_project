class ExpenseCategoryStat {
  final String category;
  final double amount;
  final double percentage;
  final int count;

  const ExpenseCategoryStat({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.count,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseCategoryStat &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          amount == other.amount &&
          percentage == other.percentage &&
          count == other.count;

  @override
  int get hashCode => Object.hash(category, amount, percentage, count);
}
