import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/features/assistant/domain/entities/assistant_message_entity.dart';
import 'package:tulap_mobile/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:tulap_mobile/features/assistant/domain/usecases/ask_assistant.dart';
import 'package:tulap_mobile/features/assistant/domain/usecases/get_assistant_suggestions.dart';
import 'package:tulap_mobile/features/assistant/presentation/controllers/assistant_controller.dart';

class FakeAssistantRepository implements AssistantRepository {
  @override
  Future<Either<Failure, AssistantMessageEntity>> query({
    required String text,
    String? contextEntityType,
    String? contextEntityId,
    String? conversationSessionId,
  }) async {
    return Right(
      AssistantMessageEntity(
        id: 'msg_101',
        sender: AssistantSender.tulap,
        text: 'Ditemukan 1 kegiatan sesuai pencarian.',
        timestamp: DateTime.now(),
        cards: const [
          AssistantCardEntity(
            id: 'act_101',
            entityType: 'ACTIVITY',
            title: 'Inspeksi Jembatan Mimika',
          ),
        ],
      ),
    );
  }

  @override
  Future<Either<Failure, List<String>>> getSuggestedQuestions({
    String? contextEntityType,
    String? contextEntityId,
  }) async {
    return const Right([
      'Kegiatan saya hari ini',
      'Cari kegiatan',
      'LPJ belum lengkap',
    ]);
  }
}

void main() {
  late AssistantController controller;
  late FakeAssistantRepository repository;
  late AskAssistant askAssistant;
  late GetAssistantSuggestions getAssistantSuggestions;

  setUp(() {
    repository = FakeAssistantRepository();
    askAssistant = AskAssistant(repository);
    getAssistantSuggestions = GetAssistantSuggestions(repository);

    controller = AssistantController(
      askAssistant: askAssistant,
      getAssistantSuggestions: getAssistantSuggestions,
    );
  });

  test('initialize loads suggestions and sets active context', () async {
    controller.initialize(
      contextEntityType: 'ACTIVITY',
      contextEntityId: 'act_101',
      contextTitle: 'Inspeksi Jembatan',
    );

    expect(controller.activeContext?.contextEntityId, 'act_101');
    expect(controller.activeContext?.contextTitle, 'Inspeksi Jembatan');

    // Wait for async suggestions
    await Future.delayed(const Duration(milliseconds: 10));
    expect(controller.suggestedQuestions.length, 3);
  });

  test('sendQuery emits user message then assistant response', () async {
    await controller.sendQuery('cari kegiatan jembatan');

    expect(controller.messages.length, 2);
    expect(controller.messages[0].sender, AssistantSender.user);
    expect(controller.messages[0].text, 'cari kegiatan jembatan');
    expect(controller.messages[1].sender, AssistantSender.tulap);
    expect(controller.messages[1].cards.length, 1);
  });

  test('clearContext and clearSession reset states correctly', () async {
    controller.initialize(
      contextEntityType: 'TRAVEL',
      contextEntityId: 'trv_001',
      contextTitle: 'Dinas Papua',
    );

    controller.clearContext();
    expect(controller.activeContext, isNull);

    controller.clearSession();
    expect(controller.messages, isEmpty);
  });
}
