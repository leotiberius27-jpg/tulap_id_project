import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/features/account/presentation/widgets/logout_protection_dialog.dart';

Future<LogoutDialogAction?> _openAndTap(
  WidgetTester tester, {
  required int pendingCount,
  required Finder tapTarget,
}) async {
  LogoutDialogAction? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await LogoutProtectionDialog.show(
                context,
                pendingCount: pendingCount,
              );
            },
            child: const Text('buka'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('buka'));
  await tester.pumpAndSettle();
  await tester.tap(tapTarget);
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('tanpa data tertunda: tombol Keluar -> logoutNow', (tester) async {
    final result = await _openAndTap(
      tester,
      pendingCount: 0,
      tapTarget: find.widgetWithText(ElevatedButton, 'Keluar'),
    );
    expect(result, LogoutDialogAction.logoutNow);
  });

  testWidgets('tombol Batal & X -> cancel', (tester) async {
    expect(
      await _openAndTap(
        tester,
        pendingCount: 0,
        tapTarget: find.widgetWithText(OutlinedButton, 'Batal'),
      ),
      LogoutDialogAction.cancel,
    );
    expect(
      await _openAndTap(
        tester,
        pendingCount: 0,
        tapTarget: find.byIcon(Icons.close_rounded),
      ),
      LogoutDialogAction.cancel,
    );
  });

  testWidgets('dengan data tertunda: Sinkronkan & Tetap Keluar', (tester) async {
    expect(
      await _openAndTap(
        tester,
        pendingCount: 3,
        tapTarget: find.widgetWithText(ElevatedButton, 'Sinkronkan'),
      ),
      LogoutDialogAction.syncNow,
    );
    expect(
      await _openAndTap(
        tester,
        pendingCount: 3,
        tapTarget: find.text('Tetap Keluar'),
      ),
      LogoutDialogAction.logoutNow,
    );
  });
}
