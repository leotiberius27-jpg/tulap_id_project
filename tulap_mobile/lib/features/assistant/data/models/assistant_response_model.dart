import '../../domain/entities/assistant_message_entity.dart';

class AssistantResponseModel {
  static AssistantMessageEntity fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'] as List<dynamic>? ?? [];
    final rawSources = json['sources'] as List<dynamic>? ?? [];
    final rawActions = json['suggestedActions'] as List<dynamic>? ?? [];
    final rawContext = json['context'] as Map<String, dynamic>?;
    final rawConfirmAction = json['confirmationAction'] as Map<String, dynamic>?;

    final cards = rawCards.map((c) {
      final map = c as Map<String, dynamic>;
      DateTime? parsedDate;
      if (map['date'] != null) {
        parsedDate = DateTime.tryParse(map['date'].toString());
      }
      return AssistantCardEntity(
        id: map['id']?.toString() ?? '',
        entityType: map['entityType']?.toString() ?? 'ACTIVITY',
        title: map['title']?.toString() ?? '',
        subtitle: map['subtitle']?.toString(),
        date: parsedDate,
        location: map['location']?.toString(),
        amount: map['amount']?.toString(),
        status: map['status']?.toString(),
        badge: map['badge']?.toString(),
        metadata: map['metadata'] as Map<String, dynamic>?,
      );
    }).toList();

    final sources = rawSources.map((s) {
      final map = s as Map<String, dynamic>;
      return AssistantSourceEntity(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        entityType: map['entityType']?.toString() ?? '',
        referenceId: map['referenceId']?.toString() ?? '',
      );
    }).toList();

    final suggestedActions = rawActions.map((a) {
      final map = a as Map<String, dynamic>;
      return _parseAction(map);
    }).toList();

    AssistantContextEntity? context;
    if (rawContext != null) {
      context = AssistantContextEntity(
        contextEntityType: rawContext['contextEntityType']?.toString() ?? '',
        contextEntityId: rawContext['contextEntityId']?.toString() ?? '',
        contextTitle: rawContext['contextTitle']?.toString(),
      );
    }

    AssistantActionEntity? confirmationAction;
    if (rawConfirmAction != null) {
      confirmationAction = _parseAction(rawConfirmAction);
    }

    return AssistantMessageEntity(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: AssistantSender.tulap,
      text: json['message']?.toString() ?? '',
      timestamp: DateTime.now(),
      cards: cards,
      sources: sources,
      suggestedActions: suggestedActions,
      context: context,
      requiresConfirmation: json['requiresConfirmation'] == true,
      confirmationAction: confirmationAction,
      isOffline: false,
    );
  }

  static AssistantActionEntity _parseAction(Map<String, dynamic> map) {
    final typeStr = map['actionType']?.toString() ?? '';
    AssistantActionType actType = AssistantActionType.unknown;

    switch (typeStr) {
      case 'OPEN_ACTIVITY':
        actType = AssistantActionType.openActivity;
        break;
      case 'OPEN_TRAVEL':
        actType = AssistantActionType.openTravel;
        break;
      case 'OPEN_EVIDENCE':
        actType = AssistantActionType.openEvidence;
        break;
      case 'OPEN_RECEIPT':
        actType = AssistantActionType.openReceipt;
        break;
      case 'OPEN_REPORT':
        actType = AssistantActionType.openReport;
        break;
      case 'OPEN_LPJ':
        actType = AssistantActionType.openLpj;
        break;
      case 'OPEN_SEARCH':
        actType = AssistantActionType.openSearch;
        break;
      case 'PREPARE_REPORT':
        actType = AssistantActionType.prepareReport;
        break;
      case 'MARK_ACTIVITY_COMPLETE':
        actType = AssistantActionType.markActivityComplete;
        break;
      case 'DELETE_CONFIRM':
        actType = AssistantActionType.deleteConfirm;
        break;
      default:
        actType = AssistantActionType.unknown;
    }

    return AssistantActionEntity(
      actionType: actType,
      label: map['label']?.toString() ?? 'Buka',
      entityId: map['entityId']?.toString(),
      payload: map['payload'] as Map<String, dynamic>?,
      isDestructive: map['isDestructive'] == true,
    );
  }
}
