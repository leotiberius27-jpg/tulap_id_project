enum AssistantSender {
  user,
  tulap,
}

enum AssistantActionType {
  openActivity,
  openTravel,
  openEvidence,
  openReceipt,
  openReport,
  openLpj,
  openSearch,
  prepareReport,
  markActivityComplete,
  deleteConfirm,
  unknown,
}

class AssistantCardEntity {
  final String id;
  final String entityType;
  final String title;
  final String? subtitle;
  final DateTime? date;
  final String? location;
  final String? amount;
  final String? status;
  final String? badge;
  final Map<String, dynamic>? metadata;

  const AssistantCardEntity({
    required this.id,
    required this.entityType,
    required this.title,
    this.subtitle,
    this.date,
    this.location,
    this.amount,
    this.status,
    this.badge,
    this.metadata,
  });
}

class AssistantSourceEntity {
  final String id;
  final String title;
  final String entityType;
  final String referenceId;

  const AssistantSourceEntity({
    required this.id,
    required this.title,
    required this.entityType,
    required this.referenceId,
  });
}

class AssistantActionEntity {
  final AssistantActionType actionType;
  final String label;
  final String? entityId;
  final Map<String, dynamic>? payload;
  final bool isDestructive;

  const AssistantActionEntity({
    required this.actionType,
    required this.label,
    this.entityId,
    this.payload,
    this.isDestructive = false,
  });
}

class AssistantContextEntity {
  final String contextEntityType;
  final String contextEntityId;
  final String? contextTitle;

  const AssistantContextEntity({
    required this.contextEntityType,
    required this.contextEntityId,
    this.contextTitle,
  });
}

class AssistantMessageEntity {
  final String id;
  final AssistantSender sender;
  final String text;
  final DateTime timestamp;
  final List<AssistantCardEntity> cards;
  final List<AssistantSourceEntity> sources;
  final List<AssistantActionEntity> suggestedActions;
  final AssistantContextEntity? context;
  final bool requiresConfirmation;
  final AssistantActionEntity? confirmationAction;
  final bool isOffline;

  const AssistantMessageEntity({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.cards = const [],
    this.sources = const [],
    this.suggestedActions = const [],
    this.context,
    this.requiresConfirmation = false,
    this.confirmationAction,
    this.isOffline = false,
  });
}
