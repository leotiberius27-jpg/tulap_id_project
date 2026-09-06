import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/assistant_message_entity.dart';
import 'assistant_card_widget.dart';
import 'assistant_source_bottom_sheet.dart';

class AssistantMessageBubble extends StatelessWidget {
  final AssistantMessageEntity message;
  final ValueChanged<AssistantCardEntity>? onOpenCard;
  final ValueChanged<AssistantActionEntity>? onExecuteAction;

  const AssistantMessageBubble({
    super.key,
    required this.message,
    this.onOpenCard,
    this.onExecuteAction,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == AssistantSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00529C), Color(0xFF0072CE)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Text bubble
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser
                          ? const Radius.circular(16)
                          : const Radius.circular(4),
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isUser ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (message.isOffline) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              size: 12,
                              color: isUser ? Colors.white70 : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Mode Offline (Data Lokal)',
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: isUser ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Cards list (if any)
                if (message.cards.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...message.cards.map((card) {
                    return AssistantCardWidget(
                      card: card,
                      onOpen: () => onOpenCard?.call(card),
                    );
                  }),
                ],

                // Sources Button (Traceability)
                if (message.sources.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () =>
                        AssistantSourceBottomSheet.show(context, message.sources),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sumber: ${message.sources.length} data Tulap.id',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Action Buttons
                if (message.suggestedActions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.suggestedActions.map((action) {
                      final isDestructive = action.isDestructive;
                      return OutlinedButton.icon(
                        icon: Icon(
                          _getActionIcon(action.actionType),
                          size: 14,
                          color: isDestructive
                              ? AppColors.danger
                              : AppColors.primary,
                        ),
                        label: Text(
                          action.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDestructive
                                ? AppColors.danger
                                : AppColors.primary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDestructive
                                ? AppColors.danger.withValues(alpha: 0.5)
                                : AppColors.primary.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => onExecuteAction?.call(action),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(AssistantActionType type) {
    switch (type) {
      case AssistantActionType.openActivity:
        return Icons.assignment_outlined;
      case AssistantActionType.openTravel:
        return Icons.flight_takeoff_outlined;
      case AssistantActionType.openEvidence:
        return Icons.photo_library_outlined;
      case AssistantActionType.openReceipt:
        return Icons.receipt_long_outlined;
      case AssistantActionType.openReport:
      case AssistantActionType.prepareReport:
        return Icons.description_outlined;
      case AssistantActionType.openLpj:
        return Icons.folder_shared_outlined;
      case AssistantActionType.openSearch:
        return Icons.search_outlined;
      case AssistantActionType.markActivityComplete:
        return Icons.check_circle_outline;
      case AssistantActionType.deleteConfirm:
        return Icons.delete_outline;
      default:
        return Icons.arrow_forward_outlined;
    }
  }
}
