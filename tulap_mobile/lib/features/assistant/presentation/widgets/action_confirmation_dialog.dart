import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/assistant_message_entity.dart';

class ActionConfirmationDialog extends StatelessWidget {
  final AssistantActionEntity action;
  final VoidCallback onConfirm;

  const ActionConfirmationDialog({
    super.key,
    required this.action,
    required this.onConfirm,
  });

  static Future<bool?> show(
    BuildContext context,
    AssistantActionEntity action,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ActionConfirmationDialog(
        action: action,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDestructive = action.isDestructive;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            isDestructive ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isDestructive ? AppColors.danger : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isDestructive ? 'Konfirmasi Tindakan' : 'Konfirmasi Aksi',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        isDestructive
          ? 'Apakah Anda yakin ingin melanjutkan tindakan ini? Aksi destruktif ini akan mengubah atau menghapus data.'
          : 'Apakah Anda ingin mengeksekusi "${action.label}"?',
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? AppColors.danger : AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            action.label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
