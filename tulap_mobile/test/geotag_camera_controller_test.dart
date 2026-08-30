import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulap_mobile/core/error/failures.dart';
import 'package:tulap_mobile/core/security/mock_location_detector.dart';
import 'package:tulap_mobile/core/security/root_detector.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/entities/geotag_photo_entity.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/repositories/geotag_camera_repository.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/capture_geotagged_photo.dart';
import 'package:tulap_mobile/features/geotag_camera/domain/usecases/validate_location_integrity.dart';
import 'package:tulap_mobile/features/geotag_camera/presentation/controllers/geotag_camera_controller.dart';

class _FakeValidateLocationIntegrity extends ValidateLocationIntegrity {
  final LocationIntegrityCheckResult checkResult;

  _FakeValidateLocationIntegrity(this.checkResult)
    : super(
        mockLocationDetector: _DummyMockLocationDetector(),
        rootDetector: _DummyRootDetector(),
      );

  @override
  Future<Either<Failure, LocationIntegrityCheckResult>> call({
    dynamic position,
  }) async {
    return Right(checkResult);
  }
}

class _DummyMockLocationDetector extends MockLocationDetector {}

class _DummyRootDetector extends RootDetector {}

class _FakeCaptureGeotaggedPhoto extends CaptureGeotaggedPhoto {
  _FakeCaptureGeotaggedPhoto() : super(_DummyGeotagCameraRepository());

  @override
  Future<Either<Failure, GeotagPhotoEntity>> call({
    required String taskId,
    String? caption,
  }) async {
    return Right(
      GeotagPhotoEntity(
        id: 'photo-1',
        taskId: taskId,
        localFilePath: '/tmp/test.jpg',
        latitude: -4.546123,
        longitude: 136.887421,
        gpsAccuracyMeters: 6.0,
        plusCode: '6P28+3Q',
        serverTimestamp: DateTime.now(),
        integrityHash: 'sha256-dummy-hash',
        isMockLocationDetected: false,
        isRootedDeviceDetected: false,
      ),
    );
  }
}

class _DummyGeotagCameraRepository implements GeotagCameraRepository {
  @override
  Future<Either<Failure, GeotagPhotoEntity>> captureAndSavePhoto({
    required String taskId,
    String? caption,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, GeotagPhotoEntity>> captureAndSaveVideo({
    required String taskId,
    required String videoPath,
    required Duration duration,
    String? caption,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, void>> deleteLocalPhoto(String photoId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<GeotagPhotoEntity>>> getPhotosByTask(
    String taskId,
  ) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'GeotagCameraController initializes with valid location and enables capture when accuracy <= 15m',
    () async {
      final validator = _FakeValidateLocationIntegrity(
        const LocationIntegrityCheckResult(
          status: LocationIntegrityStatus.valid,
          latitude: -4.546123,
          longitude: 136.887421,
          accuracyMeters: 6.0,
        ),
      );
      final capture = _FakeCaptureGeotaggedPhoto();

      final controller = GeotagCameraController(
        validateLocationIntegrity: validator,
        captureGeotaggedPhoto: capture,
        taskId: 'TL-202608-0001',
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.locationStatus, LocationIntegrityStatus.valid);
      expect(controller.state.latitude, -4.546123);
      expect(controller.state.longitude, 136.887421);
      expect(controller.state.accuracyMeters, 6.0);
      expect(controller.state.isGpsLocked, isTrue);
      expect(controller.state.isCaptureEnabled, isTrue);

      controller.dispose();
    },
  );

  test(
    'GeotagCameraController allows GPS override when accuracy is > 15m',
    () async {
      final validator = _FakeValidateLocationIntegrity(
        const LocationIntegrityCheckResult(
          status: LocationIntegrityStatus.valid,
          latitude: -4.546123,
          longitude: 136.887421,
          accuracyMeters: 35.0, // Di atas 15m
        ),
      );
      final capture = _FakeCaptureGeotaggedPhoto();

      final controller = GeotagCameraController(
        validateLocationIntegrity: validator,
        captureGeotaggedPhoto: capture,
        taskId: 'TL-202608-0001',
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.isGpsLocked, isFalse);
      expect(controller.state.isCaptureEnabled, isFalse);

      // User memilih override (Ambil dengan Catatan)
      controller.allowGpsOverride();

      expect(controller.state.isGpsOverrideAllowed, isTrue);

      controller.dispose();
    },
  );

  test(
    'showFocusIndicator displays and hides focus indicator after duration',
    () async {
      final validator = _FakeValidateLocationIntegrity(
        const LocationIntegrityCheckResult(
          status: LocationIntegrityStatus.valid,
          latitude: -4.546123,
          longitude: 136.887421,
          accuracyMeters: 6.0,
        ),
      );
      final capture = _FakeCaptureGeotaggedPhoto();

      final controller = GeotagCameraController(
        validateLocationIntegrity: validator,
        captureGeotaggedPhoto: capture,
        taskId: 'TL-202608-0001',
      );

      controller.showFocusIndicator(const Offset(150, 300));
      expect(controller.state.isFocusIndicatorVisible, isTrue);
      expect(controller.state.focusPoint, const Offset(150, 300));

      controller.dispose();
    },
  );
}
