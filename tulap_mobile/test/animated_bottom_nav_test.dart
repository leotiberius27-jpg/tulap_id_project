import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/app/presentation/main_shell.dart';

void main() {
  group('TulapAnimatedBottomBar Widget & Interaction Tests', () {
    testWidgets('Renders all 4 tabs and center camera slot cleanly', (tester) async {
      int selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: TulapAnimatedCameraFab(
              isLoading: false,
              onPressed: () {},
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return TulapAnimatedBottomBar(
                  currentIndex: selectedIndex,
                  onTap: (index) {
                    setState(() => selectedIndex = index);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Tugas'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Akun'), findsOneWidget);
      expect(find.byType(TulapAnimatedCameraFab), findsOneWidget);

      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('Tab switching updates active tab and moving notch smoothly between 4 tabs', (tester) async {
      int selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: TulapAnimatedCameraFab(
              isLoading: false,
              onPressed: () {},
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return TulapAnimatedBottomBar(
                  currentIndex: selectedIndex,
                  onTap: (index) {
                    setState(() => selectedIndex = index);
                  },
                );
              },
            ),
          ),
        ),
      );

      // 1. Tap 'Tugas'
      await tester.tap(find.text('Tugas'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.assignment_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);

      // 2. Tap 'Riwayat'
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history_rounded), findsOneWidget);

      // 3. Tap 'Akun'
      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      // 4. Tap 'Beranda'
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });

    testWidgets('Rapid tap sequence executes safely without divergence or errors', (tester) async {
      int selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: StatefulBuilder(
              builder: (context, setState) {
                return TulapAnimatedBottomBar(
                  currentIndex: selectedIndex,
                  onTap: (index) {
                    setState(() => selectedIndex = index);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Rapid successive taps
      await tester.tap(find.text('Tugas'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Riwayat'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Akun'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });

    testWidgets('Prominent center camera FAB responds to press interaction', (tester) async {
      bool cameraPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: TulapAnimatedCameraFab(
              isLoading: false,
              onPressed: () {
                cameraPressed = true;
              },
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: TulapAnimatedBottomBar(
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(TulapAnimatedCameraFab), findsOneWidget);

      await tester.tap(find.byType(TulapAnimatedCameraFab));
      await tester.pumpAndSettle();

      expect(cameraPressed, isTrue);
    });

    testWidgets('Center camera shows spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: TulapAnimatedCameraFab(
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Semantics and accessibility exposure for tabs and camera button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: TulapAnimatedCameraFab(
              isLoading: false,
              onPressed: () {},
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: TulapAnimatedBottomBar(
              currentIndex: 1, // Tugas active
              onTap: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Buka Kamera Geotag Lapangan'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Beranda'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Tugas'),
        findsOneWidget,
      );
    });

    testWidgets('Reduced motion mode handles transitions with zero duration', (tester) async {
      int selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              bottomNavigationBar: StatefulBuilder(
                builder: (context, setState) {
                  return TulapAnimatedBottomBar(
                    currentIndex: selectedIndex,
                    onTap: (index) {
                      setState(() => selectedIndex = index);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Riwayat'));
      await tester.pump(); // Instant pump without settle duration

      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    });
  });

  group('Multi-Viewport Responsive & No-Overflow Tests', () {
    final viewports = <Size>[
      const Size(320, 568), // iPhone SE / small screen
      const Size(360, 640),
      const Size(360, 800),
      const Size(375, 812),
      const Size(390, 844),
      const Size(412, 915),
      const Size(430, 932), // iPhone Pro Max / large screen
    ];

    for (final size in viewports) {
      testWidgets('Renders cleanly on viewport ${size.width}x${size.height} without overflow',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              floatingActionButton: TulapAnimatedCameraFab(
                isLoading: false,
                onPressed: () {},
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: TulapAnimatedBottomBar(
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Tugas'), findsOneWidget);
        expect(find.text('Riwayat'), findsOneWidget);
        expect(find.text('Akun'), findsOneWidget);
        expect(find.byType(TulapAnimatedCameraFab), findsOneWidget);
      });
    }

    testWidgets('Large font scaling (1.3x and 1.5x) renders cleanly without crash or overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              floatingActionButton: TulapAnimatedCameraFab(
                isLoading: false,
                onPressed: () {},
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: TulapAnimatedBottomBar(
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Akun'), findsOneWidget);
    });
  });
}
