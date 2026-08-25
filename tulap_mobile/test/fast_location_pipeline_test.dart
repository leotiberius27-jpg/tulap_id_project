import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tulap_mobile/core/geo/fast_location_service.dart';
import 'package:tulap_mobile/core/security/mock_location_detector.dart';
import 'package:tulap_mobile/core/security/root_detector.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/validate_location_integrity.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/widgets/gps_status_indicator.dart';
import 'package:flutter/material.dart';

Position _createMockPosition({
  required double latitude,
  required double longitude,
  required double accuracy,
  bool isMocked = false,
  DateTime? timestamp,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime.now(),
    accuracy: accuracy,
    altitude: 10.0,
    altitudeAccuracy: 1.0,
    heading: 0.0,
    headingAccuracy: 1.0,
    speed: 0.0,
    speedAccuracy: 1.0,
    isMocked: isMocked,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FastLocationData & Tier Logic Tests', () {
    test('Verified tier triggers when accuracy <= 15m and not mocked', () {
      final pos = _createMockPosition(
        latitude: -4.546123,
        longitude: 136.887421,
        accuracy: 8.0,
      );
      final data = FastLocationData(
        tier: LocationTier.verified,
        position: pos,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        timestamp: DateTime.now(),
      );

      expect(data.isGpsLocked, isTrue);
      expect(data.isAcceptable, isTrue);
      expect(data.isUsableForCapture, isTrue);
    });

    test(
      'Fresh refining tier when accuracy is 22m (acceptable but not locked)',
      () {
        final pos = _createMockPosition(
          latitude: -4.546123,
          longitude: 136.887421,
          accuracy: 22.0,
        );
        final data = FastLocationData(
          tier: LocationTier.freshRefining,
          position: pos,
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          timestamp: DateTime.now(),
        );

        expect(data.isGpsLocked, isFalse);
        expect(data.isAcceptable, isTrue);
        expect(data.isUsableForCapture, isFalse);
      },
    );

    test('Mock location blocks usable capture', () {
      final pos = _createMockPosition(
        latitude: -4.546123,
        longitude: 136.887421,
        accuracy: 5.0,
        isMocked: true,
      );
      final data = FastLocationData(
        tier: LocationTier.mocked,
        position: pos,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        timestamp: DateTime.now(),
        isMocked: true,
      );

      expect(data.isGpsLocked, isTrue);
      expect(data.isUsableForCapture, isFalse);
    });
  });

  group('MockLocationDetector Evaluation Tests', () {
    final detector = MockLocationDetector();

    test('evaluatePosition validates clean position correctly', () {
      final pos = _createMockPosition(
        latitude: -4.1234,
        longitude: 136.5678,
        accuracy: 10.0,
      );
      final result = detector.evaluatePosition(pos);

      expect(result.isValid, isTrue);
      expect(result.isMockLocationDetected, isFalse);
      expect(result.accuracyInMeters, 10.0);
    });

    test('evaluatePosition flags mock location', () {
      final pos = _createMockPosition(
        latitude: -4.1234,
        longitude: 136.5678,
        accuracy: 5.0,
        isMocked: true,
      );
      final result = detector.evaluatePosition(pos);

      expect(result.isValid, isFalse);
      expect(result.isMockLocationDetected, isTrue);
    });

    test('evaluatePosition flags poor accuracy (> 50m)', () {
      final pos = _createMockPosition(
        latitude: -4.1234,
        longitude: 136.5678,
        accuracy: 65.0,
      );
      final result = detector.evaluatePosition(pos);

      expect(result.isValid, isFalse);
      expect(result.accuracyInMeters, 65.0);
    });
  });

  group('ValidateLocationIntegrity with Fast Evaluation Tests', () {
    test('evaluates pre-fetched position instantly without I/O', () async {
      final detector = MockLocationDetector();
      final rootDetector = RootDetector();
      final usecase = ValidateLocationIntegrity(
        mockLocationDetector: detector,
        rootDetector: rootDetector,
      );

      final pos = _createMockPosition(
        latitude: -4.1234,
        longitude: 136.5678,
        accuracy: 12.0,
      );
      final resultEither = await usecase.call(position: pos);

      expect(resultEither.isRight(), isTrue);
      resultEither.fold((_) => fail('Should succeed'), (res) {
        expect(res.status, LocationIntegrityStatus.valid);
        expect(res.latitude, -4.1234);
        expect(res.longitude, 136.5678);
        expect(res.accuracyMeters, 12.0);
      });
    });
  });

  group('GpsStatusIndicator Widget Tests', () {
    testWidgets('renders verified GPS status badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GpsStatusIndicator(
              status: LocationIntegrityStatus.valid,
              tier: LocationTier.verified,
              accuracyMeters: 8.0,
            ),
          ),
        ),
      );

      expect(find.text('GPS Akurat • ±8m'), findsOneWidget);
    });

    testWidgets('renders fast initial location badge correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GpsStatusIndicator(
              status: LocationIntegrityStatus.valid,
              tier: LocationTier.fastInitial,
              accuracyMeters: 42.0,
            ),
          ),
        ),
      );

      expect(find.text('Lokasi Sementara • ±42m'), findsOneWidget);
    });

    testWidgets('renders preparing GPS badge correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GpsStatusIndicator(
              status: LocationIntegrityStatus.checking,
              tier: LocationTier.none,
            ),
          ),
        ),
      );

      expect(find.text('Menyiapkan GPS...'), findsOneWidget);
    });
  });
}
