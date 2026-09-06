import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/session/auth_session_manager.dart';
import '../../../../core/sync/background_sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/domain/usecases/get_current_session.dart';
import '../../../sync_queue/domain/repositories/sync_queue_repository.dart';
import '../../../sync_queue/presentation/controllers/sync_center_controller.dart';
import '../../../sync_queue/presentation/pages/sync_center_page.dart';
import '../../../task_detail/domain/usecases/get_active_tasks.dart';
import '../../../task_list/presentation/controllers/task_list_controller.dart';
import '../../../task_list/presentation/pages/task_list_page.dart';
import '../controllers/assistant_controller.dart';
import '../controllers/tula_visibility_controller.dart';
import '../pages/tanya_tulap_page.dart';
import 'assistant_message_bubble.dart';
import 'tula_context_summary.dart';
import 'tula_offline_state.dart';
import 'tula_quick_actions.dart';

/// TulaBottomSheet
/// ----------------------------------------------------------------------
/// Entry point utama Tula (dibuka lewat TulaFloatingButton). BUKAN
/// halaman chatbot kosong - langsung menyapa dengan nama user, ringkasan
/// kontekstual (kalau ada), dan quick actions relevan sebelum user
/// mengetik apapun. Mesin percakapan & backend TIDAK dibuat baru - sheet
/// ini memakai AssistantController/AskAssistant yang sama dengan Tanya
/// Tulap penuh (lihat TanyaTulapPage), hanya UI entry-nya yang berbeda.
/// ----------------------------------------------------------------------
class TulaBottomSheet extends StatefulWidget {
  const TulaBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    final tula = sl<TulaVisibilityController>();
    tula.setSheetOpen(true);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TulaBottomSheet(),
    ).whenComplete(() => tula.setSheetOpen(false));
  }

  @override
  State<TulaBottomSheet> createState() => _TulaBottomSheetState();
}

class _TulaBottomSheetState extends State<TulaBottomSheet> {
  late final TulaVisibilityController _tula;
  late final AssistantController _assistant;
  late final TulaContextData _context;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tula = sl<TulaVisibilityController>();
    _context = _tula.current;
    _assistant = sl<AssistantController>();

    final taskSummary = _context.taskSummary;
    _assistant.initialize(
      contextEntityType:
          _context.screen == TulaScreenContext.taskDetail ? 'ACTIVITY' : null,
      contextEntityId: taskSummary?.taskId,
      contextTitle: taskSummary?.taskTitle,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send([String? preset]) {
    final query = preset ?? _textController.text.trim();
    if (query.isEmpty) return;
    _textController.clear();
    HapticFeedback.selectionClick();
    _assistant.sendQuery(query);
    _scrollToBottom();
  }

  /// Percakapan mendalam (buka kartu/eksekusi aksi lanjutan) dilanjutkan
  /// di halaman Tanya Tulap penuh yang sudah punya seluruh logika
  /// navigasi & konfirmasi aksi kritis - sheet ini tidak menduplikasi.
  void _continueInFullAssistant() {
    final taskSummary = _context.taskSummary;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TanyaTulapPage(
          contextEntityType: _context.screen == TulaScreenContext.taskDetail
              ? 'ACTIVITY'
              : null,
          contextEntityId: taskSummary?.taskId,
          contextTitle: taskSummary?.taskTitle,
        ),
      ),
    );
  }

  void _openTaskList() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<TaskListController>(
          create: (_) => TaskListController(
            getActiveTasks: sl<GetActiveTasks>(),
            getCurrentSession: sl<GetCurrentSession>(),
          ),
          child: const TaskListPage(),
        ),
      ),
    );
  }

  void _openSyncCenter() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<SyncCenterController>(
          create: (_) => SyncCenterController(
            repository: sl<SyncQueueRepository>(),
            backgroundSyncService: sl<BackgroundSyncService>(),
          ),
          child: const SyncCenterPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tulapColors;
    final mediaQuery = MediaQuery.of(context);

    return AnimatedBuilder(
      animation: _tula,
      builder: (context, _) {
        final isOnline = _tula.isOnline;

        return Padding(
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.86),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildHeader(colors),
                Divider(height: 1, color: colors.border),
                Flexible(
                  child: isOnline ? _buildOnlineBody(colors) : _buildOfflineBody(),
                ),
                if (isOnline) _buildComposer(colors),
                SizedBox(height: mediaQuery.padding.bottom > 0 ? 8 : 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(TulapThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF00529C), Color(0xFF0072CE)],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tula',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                'Asisten Tulap.id',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBody() {
    return SingleChildScrollView(
      child: TulaOfflineState(
        onLihatTugas: _openTaskList,
        onLihatDataTersimpan: _openSyncCenter,
      ),
    );
  }

  Widget _buildOnlineBody(TulapThemeColors colors) {
    return ChangeNotifierProvider<AssistantController>.value(
      value: _assistant,
      child: Consumer<AssistantController>(
        builder: (context, controller, _) {
          if (controller.messages.isEmpty) {
            return _buildWelcome(controller);
          }
          return _buildConversation(controller);
        },
      ),
    );
  }

  Widget _buildWelcome(AssistantController controller) {
    final firstName =
        (sl<AuthSessionManager>().currentUser?.fullName ?? 'Pengguna')
            .trim()
            .split(RegExp(r'\s+'))
            .first;
    final taskSummary = _context.taskSummary;

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Halo, $firstName.\nAda yang bisa saya bantu?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35),
          ),
        ),
        if (_context.screen == TulaScreenContext.taskDetail && taskSummary != null) ...[
          const SizedBox(height: 14),
          TulaContextSummary(
            summary: taskSummary,
            onPrimaryAction: () => Navigator.of(context).pop(),
          ),
        ],
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TulaQuickActions(
            actions: tulaQuickActionsFor(_context.screen),
            onSelect: _send,
          ),
        ),
      ],
    );
  }

  Widget _buildConversation(AssistantController controller) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: controller.messages.length + (controller.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == controller.messages.length && controller.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'Tula sedang memeriksa data...',
                  style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        }
        final message = controller.messages[index];
        final hasFollowUp =
            message.cards.isNotEmpty || message.suggestedActions.isNotEmpty;
        return AssistantMessageBubble(
          message: message,
          onOpenCard: hasFollowUp ? (_) => _continueInFullAssistant() : null,
          onExecuteAction: hasFollowUp ? (_) => _continueInFullAssistant() : null,
        );
      },
    );
  }

  Widget _buildComposer(TulapThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.border),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Tanyakan sesuatu...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _send(),
            icon: const Icon(Icons.send_rounded),
            color: colors.primary,
          ),
        ],
      ),
    );
  }
}
