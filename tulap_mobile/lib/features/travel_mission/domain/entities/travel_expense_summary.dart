import '../../../expense_ocr/domain/entities/expense_note_entity.dart';

class TravelExpenseAnomaly {
  final String id;
  final String title;
  final String description;
  final bool isBlocker;

  const TravelExpenseAnomaly({
    required this.id,
    required this.title,
    required this.description,
    this.isBlocker = false,
  });
}

class TravelExpenseSummary {
  final List<ExpenseNoteEntity> directExpenses;
  final List<ExpenseNoteEntity> activityExpenses;
  final double totalDirectAmount;
  final double totalActivityAmount;
  final double totalActualExpense;
  final double estimatedBudget;
  final double varianceAmount; // estimatedBudget - totalActualExpense
  final Map<ExpenseCategoryEntity, double> categoryBreakdown;
  final List<TravelExpenseAnomaly> anomalies;

  const TravelExpenseSummary({
    required this.directExpenses,
    required this.activityExpenses,
    required this.totalDirectAmount,
    required this.totalActivityAmount,
    required this.totalActualExpense,
    required this.estimatedBudget,
    required this.varianceAmount,
    required this.categoryBreakdown,
    this.anomalies = const [],
  });

  int get totalReceiptCount => directExpenses.length + activityExpenses.length;
}
