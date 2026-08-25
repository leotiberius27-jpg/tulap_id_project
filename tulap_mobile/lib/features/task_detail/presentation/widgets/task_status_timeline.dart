import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/task_entity.dart';

/// TaskStatusTimeline
/// ----------------------------------------------------------------------
/// Stepper vertikal progres tugas. Ditampilkan berdasarkan STATUS
/// sebenarnya dari `TaskEntity.status` saja - backend belum mengekspos
/// riwayat waktu per-tahap (kapan tepatnya "mulai", "kirim", dst) ke
/// mobile, jadi timeline ini SENGAJA tidak menampilkan jam/tanggal palsu
/// per-langkah. Yang ditampilkan cuma tahap mana yang sudah terlewati
/// (berdasarkan urutan status yang valid) vs yang belum - jujur sesuai
/// data yang benar-benar ada.
/// ----------------------------------------------------------------------
class TaskStatusTimeline extends StatelessWidget {
  final TaskEntity task;

  const TaskStatusTimeline({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final steps = _stepsFor(task.status);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineRow(step: steps[i], isLast: i == steps.length - 1),
      ],
    );
  }

  List<_Step> _stepsFor(TaskStatusEntity status) {
    final isRejected = status == TaskStatusEntity.rejected;
    final isRevision = status == TaskStatusEntity.revisionNeeded;

    const order = [
      TaskStatusEntity.draft,
      TaskStatusEntity.ongoing,
      TaskStatusEntity.pendingVerification,
      TaskStatusEntity.verified,
    ];
    final currentIndex = isRejected || isRevision
        ? order.indexOf(TaskStatusEntity.pendingVerification)
        : order.indexOf(
            status == TaskStatusEntity.completed
                ? TaskStatusEntity.verified
                : status,
          );

    final labels = {
      TaskStatusEntity.draft: ('Tugas Dibuat', Icons.assignment_outlined),
      TaskStatusEntity.ongoing: ('Sedang Dikerjakan', Icons.directions_walk),
      TaskStatusEntity.pendingVerification: (
        'Menunggu Verifikasi',
        Icons.hourglass_top,
      ),
      TaskStatusEntity.verified: ('Terverifikasi', Icons.verified),
    };

    final steps = <_Step>[];
    for (var i = 0; i < order.length; i++) {
      final s = order[i];
      final (label, icon) = labels[s]!;
      steps.add(
        _Step(
          label: label,
          icon: icon,
          state: i < currentIndex
              ? _StepState.done
              : i == currentIndex
              ? _StepState.current
              : _StepState.upcoming,
        ),
      );
    }

    if (isRevision) {
      steps.add(
        const _Step(
          label: 'Perlu Diperbaiki',
          icon: Icons.edit_note,
          state: _StepState.warning,
        ),
      );
    } else if (isRejected) {
      steps.add(
        const _Step(
          label: 'Ditolak',
          icon: Icons.cancel,
          state: _StepState.danger,
        ),
      );
    }

    return steps;
  }
}

enum _StepState { done, current, upcoming, warning, danger }

class _Step {
  final String label;
  final IconData icon;
  final _StepState state;
  const _Step({required this.label, required this.icon, required this.state});
}

class _TimelineRow extends StatelessWidget {
  final _Step step;
  final bool isLast;

  const _TimelineRow({required this.step, required this.isLast});

  Color get _color {
    switch (step.state) {
      case _StepState.done:
        return AppColors.success;
      case _StepState.current:
        return AppColors.action;
      case _StepState.upcoming:
        return AppColors.border;
      case _StepState.warning:
        return AppColors.warning;
      case _StepState.danger:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final isUpcoming = step.state == _StepState.upcoming;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? AppColors.background
                      : color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Icon(step.icon, size: 13, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: isUpcoming
                        ? AppColors.border
                        : color.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.base, top: 3),
            child: Text(
              step.label,
              style: AppTypography.small.copyWith(
                color: isUpcoming
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontWeight: step.state == _StepState.current
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
