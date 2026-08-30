class CompletenessChecklistItem {
  final String id;
  final String label;
  final String description;
  final bool isMandatory;
  final bool isCompleted;
  final String? statusDetail;

  const CompletenessChecklistItem({
    required this.id,
    required this.label,
    required this.description,
    required this.isMandatory,
    required this.isCompleted,
    this.statusDetail,
  });
}

class TravelCompletenessResult {
  final double score; // 0.0 - 1.0
  final int percentage; // 0 - 100
  final bool isReadyForLpj;
  final List<CompletenessChecklistItem> items;
  final List<String> blockers;
  final List<String> warnings;

  const TravelCompletenessResult({
    required this.score,
    required this.percentage,
    required this.isReadyForLpj,
    required this.items,
    required this.blockers,
    required this.warnings,
  });

  int get completedCount => items.where((e) => e.isCompleted).length;
  int get totalCount => items.length;
}
