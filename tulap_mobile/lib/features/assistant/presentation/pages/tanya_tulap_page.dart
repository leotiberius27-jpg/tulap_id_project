import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../app/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../lpj/presentation/pages/lpj_summary_page.dart';
import '../../../search_archive/domain/entities/search_filter_state.dart';
import '../../../search_archive/domain/entities/search_result_entity.dart';
import '../../../task_detail/presentation/pages/task_detail_page.dart';
import '../../../travel_mission/presentation/pages/travel_mission_detail_page.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../controllers/assistant_controller.dart';
import '../widgets/action_confirmation_dialog.dart';
import '../widgets/assistant_message_bubble.dart';
import '../widgets/suggested_questions_section.dart';

class TanyaTulapPage extends StatefulWidget {
  final AssistantController? controller;
  final String? contextEntityType;
  final String? contextEntityId;
  final String? contextTitle;

  const TanyaTulapPage({
    super.key,
    this.controller,
    this.contextEntityType,
    this.contextEntityId,
    this.contextTitle,
  });

  @override
  State<TanyaTulapPage> createState() => _TanyaTulapPageState();
}

class _TanyaTulapPageState extends State<TanyaTulapPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AssistantController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? sl<AssistantController>();
    _controller.initialize(
      contextEntityType: widget.contextEntityType,
      contextEntityId: widget.contextEntityId,
      contextTitle: widget.contextTitle,
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

  void _handleSend([String? presetQuery]) {
    final query = presetQuery ?? _textController.text.trim();
    if (query.isEmpty) return;

    _textController.clear();
    HapticFeedback.selectionClick();
    _controller.sendQuery(query);
    _scrollToBottom();
  }

  void _handleOpenCard(AssistantCardEntity card) {
    HapticFeedback.selectionClick();
    switch (card.entityType.toUpperCase()) {
      case 'ACTIVITY':
      case 'TASK':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const TaskDetailPage(
              officerName: 'Petugas Lapangan',
              agencyName: 'Dinas Pekerjaan Umum',
            ),
          ),
        );
        break;
      case 'TRAVEL':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TravelMissionDetailPage(travelId: card.id),
          ),
        );
        break;
      case 'LPJ':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LpjSummaryPage(taskId: card.id),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryPage(
              initialQuery: card.title,
            ),
          ),
        );
    }
  }

  Future<void> _handleExecuteAction(AssistantActionEntity action) async {
    HapticFeedback.selectionClick();

    if (action.isDestructive ||
        action.actionType == AssistantActionType.markActivityComplete ||
        action.actionType == AssistantActionType.deleteConfirm) {
      final confirmed = await ActionConfirmationDialog.show(context, action);
      if (confirmed != true) return;
    }

    if (!mounted) return;

    switch (action.actionType) {
      case AssistantActionType.openActivity:
        if (action.entityId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TaskDetailPage(
                officerName: 'Petugas Lapangan',
                agencyName: 'Dinas Pekerjaan Umum',
              ),
            ),
          );
        }
        break;
      case AssistantActionType.openTravel:
        if (action.entityId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TravelMissionDetailPage(travelId: action.entityId!),
            ),
          );
        }
        break;
      case AssistantActionType.openLpj:
        if (action.entityId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LpjSummaryPage(taskId: action.entityId!),
            ),
          );
        }
        break;
      case AssistantActionType.openSearch:
        final query = action.payload?['query']?.toString();
        final typeStr = action.payload?['entityType']?.toString();
        SearchEntityType? searchType;
        if (typeStr == 'ACTIVITY') searchType = SearchEntityType.activity;
        if (typeStr == 'TRAVEL') searchType = SearchEntityType.travel;
        if (typeStr == 'RECEIPT') searchType = SearchEntityType.receipt;
        if (typeStr == 'LPJ') searchType = SearchEntityType.lpj;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryPage(
              initialQuery: query,
              initialFilter: searchType != null
                  ? SearchFilterState(selectedType: searchType)
                  : null,
            ),
          ),
        );
        break;
      case AssistantActionType.markActivityComplete:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kegiatan berhasil ditandai selesai.'),
            backgroundColor: AppColors.success,
          ),
        );
        break;
      case AssistantActionType.deleteConfirm:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aksi penghapusan data telah dikonfirmasi.'),
            backgroundColor: AppColors.danger,
          ),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AssistantController>.value(
      value: _controller,
      child: Consumer<AssistantController>(
        builder: (context, controller, _) {
          final activeCtx = controller.activeContext;

          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanya Tulap',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  if (activeCtx != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Konteks: ${activeCtx.contextTitle ?? activeCtx.contextEntityType}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              actions: [
                if (activeCtx != null)
                  IconButton(
                    icon: const Icon(Icons.link_off, size: 20),
                    tooltip: 'Hapus Konteks',
                    onPressed: () {
                      controller.clearContext();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Konteks spesifik dinonaktifkan.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Mulai Ulang Percakapan',
                  onPressed: () {
                    controller.clearSession();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Percakapan telah direset.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Active context pill (if active)
                  if (activeCtx != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: AppColors.primary.withValues(alpha: 0.06),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Asisten terhubung ke: ${activeCtx.contextTitle ?? activeCtx.contextEntityType}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => controller.clearContext(),
                            child: const Icon(Icons.close,
                                size: 16, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                  // Conversation Area
                  Expanded(
                    child: controller.messages.isEmpty
                        ? _buildWelcomeState(controller)
                        : _buildMessageList(controller),
                  ),

                  // Suggested chips at bottom when conversation active
                  if (controller.messages.isNotEmpty &&
                      controller.suggestedQuestions.isNotEmpty)
                    SuggestedQuestionsSection(
                      suggestions: controller.suggestedQuestions,
                      onSelectSuggestion: _handleSend,
                    ),

                  // Bottom Input Field
                  _buildInputBar(controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeState(AssistantController controller) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00529C), Color(0xFF0072CE)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Halo 👋\nAda yang bisa Tulap bantu?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tanyakan informasi kegiatan lapangan, nota pengeluaran, dokumentasi foto, berkas LPJ, atau perjalanan dinas Anda secara alami.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        SuggestedQuestionsSection(
          suggestions: controller.suggestedQuestions,
          onSelectSuggestion: _handleSend,
        ),
      ],
    );
  }

  Widget _buildMessageList(AssistantController controller) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      itemCount: controller.messages.length + (controller.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == controller.messages.length && controller.isLoading) {
          return _buildLoadingBubble();
        }

        final message = controller.messages[index];
        return AssistantMessageBubble(
          message: message,
          onOpenCard: _handleOpenCard,
          onExecuteAction: _handleExecuteAction,
        );
      },
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              child:
                  Icon(Icons.auto_awesome_rounded, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Tulap sedang mencari data & memverifikasi...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(AssistantController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.chat_bubble_outline,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Tanyakan tentang kegiatan, nota, LPJ...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: controller.isLoading ? null : () => _handleSend(),
            icon: const Icon(Icons.send_rounded),
            color: AppColors.primary,
            disabledColor: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
