import 'package:flutter/foundation.dart';
import '../../domain/entities/assistant_message_entity.dart';
import '../../domain/usecases/ask_assistant.dart';
import '../../domain/usecases/get_assistant_suggestions.dart';

class AssistantController extends ChangeNotifier {
  final AskAssistant askAssistant;
  final GetAssistantSuggestions getAssistantSuggestions;

  AssistantController({
    required this.askAssistant,
    required this.getAssistantSuggestions,
  });

  final List<AssistantMessageEntity> _messages = [];
  List<AssistantMessageEntity> get messages => List.unmodifiable(_messages);

  List<String> _suggestedQuestions = [];
  List<String> get suggestedQuestions => List.unmodifiable(_suggestedQuestions);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AssistantContextEntity? _activeContext;
  AssistantContextEntity? get activeContext => _activeContext;

  String _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
  String get sessionId => _sessionId;

  int _requestSequence = 0;

  void initialize({
    String? contextEntityType,
    String? contextEntityId,
    String? contextTitle,
  }) {
    if (contextEntityType != null && contextEntityId != null) {
      _activeContext = AssistantContextEntity(
        contextEntityType: contextEntityType,
        contextEntityId: contextEntityId,
        contextTitle: contextTitle,
      );
    }
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final result = await getAssistantSuggestions(
      contextEntityType: _activeContext?.contextEntityType,
      contextEntityId: _activeContext?.contextEntityId,
    );

    result.fold(
      (_) => _suggestedQuestions = [],
      (s) {
        _suggestedQuestions = s;
        notifyListeners();
      },
    );
  }

  Future<void> sendQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || _isLoading) return;

    final userMessage = AssistantMessageEntity(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      sender: AssistantSender.user,
      text: trimmed,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final currentSeq = ++_requestSequence;

    final result = await askAssistant(
      text: trimmed,
      contextEntityType: _activeContext?.contextEntityType,
      contextEntityId: _activeContext?.contextEntityId,
      conversationSessionId: _sessionId,
    );

    // Stale request protection
    if (currentSeq != _requestSequence) return;

    _isLoading = false;

    result.fold(
      (failure) {
        _errorMessage = 'Gagal memproses pertanyaan. Silakan coba lagi.';
        _messages.add(
          AssistantMessageEntity(
            id: 'msg_err_${DateTime.now().millisecondsSinceEpoch}',
            sender: AssistantSender.tulap,
            text: 'Maaf, terjadi kendala saat memproses pertanyaan Anda.',
            timestamp: DateTime.now(),
          ),
        );
      },
      (assistantMessage) {
        _messages.add(assistantMessage);
        // Bound conversation history to prevent memory leaks (keep last 40)
        if (_messages.length > 40) {
          _messages.removeRange(0, _messages.length - 40);
        }
      },
    );

    notifyListeners();
  }

  void clearContext() {
    _activeContext = null;
    _loadSuggestions();
    notifyListeners();
  }

  void clearSession() {
    _messages.clear();
    _activeContext = null;
    _errorMessage = null;
    _isLoading = false;
    _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    _loadSuggestions();
    notifyListeners();
  }
}
