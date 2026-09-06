import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/features/assistant/domain/usecases/ask_assistant.dart';
import 'package:tulap_mobile/features/assistant/domain/usecases/get_assistant_suggestions.dart';
import 'package:tulap_mobile/features/assistant/presentation/controllers/assistant_controller.dart';
import 'package:tulap_mobile/features/assistant/presentation/pages/tanya_tulap_page.dart';
import 'package:tulap_mobile/features/assistant/presentation/widgets/assistant_message_bubble.dart';

import 'assistant_controller_test.dart';

void main() {
  late AssistantController controller;
  late FakeAssistantRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeAssistantRepository();
    final ask = AskAssistant(fakeRepo);
    final getSug = GetAssistantSuggestions(fakeRepo);

    controller = AssistantController(
      askAssistant: ask,
      getAssistantSuggestions: getSug,
    );
  });

  testWidgets(
      'TanyaTulapPage renders welcome state, suggestions, and handles input',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TanyaTulapPage(controller: controller),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Welcome text and header
    expect(find.text('Tanya Tulap'), findsOneWidget);
    expect(find.textContaining('Ada yang bisa Tulap bantu?'), findsOneWidget);
    expect(find.text('Kegiatan saya hari ini'), findsOneWidget);

    // Tap on suggested chip
    await tester.tap(find.text('Kegiatan saya hari ini'));
    await tester.pumpAndSettle();

    // Verify messages list rendered (2 bubbles: user + assistant)
    expect(find.byType(AssistantMessageBubble), findsNWidgets(2));
    expect(find.text('Ditemukan 1 kegiatan sesuai pencarian.'), findsOneWidget);
    expect(find.text('Inspeksi Jembatan Mimika'), findsOneWidget);
  });
}
