import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../task_detail/presentation/controllers/task_detail_controller.dart';
import '../controllers/tula_visibility_controller.dart';

/// TulaTaskContextBinder
/// ----------------------------------------------------------------------
/// Mendaftarkan konteks "Detail Tugas" ke TulaVisibilityController selama
/// TaskDetailPage aktif (push saat masuk, pop saat keluar) dan
/// menyegarkan ringkasan bukti/checklist setiap kali TaskDetailController
/// berubah - agar insight Tula memakai data NYATA yang sudah dimuat
/// halaman ini, bukan data tiruan.
/// ----------------------------------------------------------------------
class TulaTaskContextBinder extends StatefulWidget {
  final Widget child;

  const TulaTaskContextBinder({super.key, required this.child});

  @override
  State<TulaTaskContextBinder> createState() => _TulaTaskContextBinderState();
}

class _TulaTaskContextBinderState extends State<TulaTaskContextBinder> {
  late final TulaVisibilityController _tula;

  @override
  void initState() {
    super.initState();
    _tula = sl<TulaVisibilityController>();
    _tula.pushContext(const TulaContextData(TulaScreenContext.taskDetail));
  }

  @override
  void dispose() {
    _tula.popContext();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TaskDetailController>().state;
    final task = state.task;

    if (task != null) {
      final summary = TulaTaskSummary(
        taskId: task.id,
        taskTitle: task.taskName,
        checklistTotal: task.checklistItems.length,
        checklistDone: task.checklistItems.where((c) => c.isCompleted).length,
        evidenceCount: state.photos.length,
        hasReceipt: state.expenses.isNotEmpty,
        hasNote: state.notes.isNotEmpty,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Halaman lain bisa saja sudah di-push DI ATAS Detail Tugas ini
        // (mis. LPJ) tanpa men-dispose widget ini (Navigator hanya
        // menumpuk route baru) - jangan timpa konteks/insight milik
        // layar yang sekarang benar-benar di atas.
        if (_tula.current.screen != TulaScreenContext.taskDetail) return;

        _tula.updateTop(
          TulaContextData(TulaScreenContext.taskDetail, taskSummary: summary),
        );

        final message = summary.checklistRemaining > 0
            ? '${summary.checklistRemaining} checklist belum selesai'
            : !summary.hasReceipt
                ? 'Nota belum dilampirkan'
                : null;
        _tula.setInsight(
          has: message != null,
          severity: message != null ? TulaInsightSeverity.warning : null,
          message: message,
        );
      });
    }

    return widget.child;
  }
}
