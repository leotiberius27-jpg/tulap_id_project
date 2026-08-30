enum ActionRequiredType {
  lpjIncomplete,
  pendingSync,
  receiptNeedsReview,
  activityIncomplete,
  integrityIssue,
}

enum ActionRequiredSeverity {
  warning,
  info,
  danger,
}

class ActionRequiredEntity {
  final ActionRequiredType type;
  final String title;
  final String subtitle;
  final int count;
  final ActionRequiredSeverity severity;
  final Map<String, dynamic>? filterParams;

  const ActionRequiredEntity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.count,
    this.severity = ActionRequiredSeverity.warning,
    this.filterParams,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionRequiredEntity &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          title == other.title &&
          subtitle == other.subtitle &&
          count == other.count &&
          severity == other.severity;

  @override
  int get hashCode => Object.hash(type, title, subtitle, count, severity);
}
