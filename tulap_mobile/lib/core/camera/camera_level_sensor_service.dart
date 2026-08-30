import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

/// CameraLevelData
/// ----------------------------------------------------------------------
/// Data sudut kemiringan (roll/horizon) kamera secara real-time.
/// ----------------------------------------------------------------------
class CameraLevelData {
  final double rollDegrees;
  final bool isLevel;

  const CameraLevelData({
    required this.rollDegrees,
    required this.isLevel,
  });
}

/// CameraLevelSensorService
/// ----------------------------------------------------------------------
/// Membaca sensor accelerometer perangkat untuk mendeteksi waterpass/horizon kamera.
/// Pembaruan di-throttle untuk efisiensi performa 60 FPS pada UI overlay.
/// ----------------------------------------------------------------------
class CameraLevelSensorService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  final _controller = StreamController<CameraLevelData>.broadcast();
  DateTime _lastEmitTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _throttleMs = 40; // ~25 FPS sensor update

  Stream<CameraLevelData> get levelStream => _controller.stream;

  /// Memulai pembacaan sensor
  void start() {
    _subscription?.cancel();
    try {
      _subscription = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen((event) {
        final now = DateTime.now();
        if (now.difference(_lastEmitTime).inMilliseconds < _throttleMs) {
          return;
        }
        _lastEmitTime = now;

        // Hitung sudut kemiringan ponsel dalam derajat (roll angle)
        // Posisi tegak lurus portrait: x mendekati 0, y mendekati 9.8
        final rollRadians = math.atan2(event.x, event.y);
        var rollDegrees = rollRadians * (180.0 / math.pi);

        // Standarisasi sudut: saat tegak lurus sudut adalah 0 derajat
        if (rollDegrees > 90) rollDegrees = 180 - rollDegrees;
        if (rollDegrees < -90) rollDegrees = -180 - rollDegrees;

        final isLevel = rollDegrees.abs() <= 1.5;

        _controller.add(
          CameraLevelData(
            rollDegrees: rollDegrees,
            isLevel: isLevel,
          ),
        );
      }, onError: (_) {});
    } catch (_) {}
  }

  /// Menghentikan pembacaan sensor
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Membersihkan resource
  void dispose() {
    stop();
    _controller.close();
  }
}
