import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tulap_mobile/features/quick_geotag/presentation/controllers/quick_geotag_controller.dart';

final _now = DateTime(2026, 10, 13, 12);

Position _pos({
  required double accuracy,
  required int ageSeconds,
  bool isMocked = false,
}) {
  return Position(
    latitude: -4.5559,
    longitude: 136.8930,
    timestamp: _now.subtract(Duration(seconds: ageSeconds)),
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
  group('GeotagLockPolicy.selectBest', () {
    test('returns null when every sample is older than 30s', () {
      final best = GeotagLockPolicy.selectBest(
        [_pos(accuracy: 5, ageSeconds: 31), _pos(accuracy: 3, ageSeconds: 60)],
        _now,
      );
      expect(best, isNull);
    });

    test('prefers the more accurate sample at similar age', () {
      final accurate = _pos(accuracy: 8, ageSeconds: 2);
      final best = GeotagLockPolicy.selectBest(
        [_pos(accuracy: 40, ageSeconds: 1), accurate],
        _now,
      );
      expect(best, same(accurate));
    });

    test('a fresh sample beats a slightly more accurate stale one', () {
      // 5 m + 20 s * 1.5 = 35 m effective vs 12 m + 0 = 12 m.
      final fresh = _pos(accuracy: 12, ageSeconds: 0);
      final best = GeotagLockPolicy.selectBest(
        [_pos(accuracy: 5, ageSeconds: 20), fresh],
        _now,
      );
      expect(best, same(fresh));
    });

    test('still picks a weak indoor fix when it is the only one', () {
      final weak = _pos(accuracy: 200, ageSeconds: 1);
      expect(GeotagLockPolicy.selectBest([weak], _now), same(weak));
    });

    test('future timestamps (clock skew) count as age zero', () {
      final skewed = _pos(accuracy: 10, ageSeconds: -3);
      expect(GeotagLockPolicy.ageOf(skewed, _now), Duration.zero);
      expect(GeotagLockPolicy.selectBest([skewed], _now), same(skewed));
    });
  });

  group('GeotagLockPolicy.isInstantLockable', () {
    test('fresh and accurate locks instantly', () {
      expect(
        GeotagLockPolicy.isInstantLockable(
          _pos(accuracy: 15, ageSeconds: 5),
          _now,
        ),
        isTrue,
      );
    });

    test('inaccurate or older than 5s does not', () {
      expect(
        GeotagLockPolicy.isInstantLockable(
          _pos(accuracy: 16, ageSeconds: 1),
          _now,
        ),
        isFalse,
      );
      expect(
        GeotagLockPolicy.isInstantLockable(
          _pos(accuracy: 5, ageSeconds: 6),
          _now,
        ),
        isFalse,
      );
    });
  });

  group('GeotagLockPolicy.containsMocked', () {
    test('flags a usable mocked sample even if it is not the best', () {
      expect(
        GeotagLockPolicy.containsMocked([
          _pos(accuracy: 5, ageSeconds: 1),
          _pos(accuracy: 50, ageSeconds: 3, isMocked: true),
        ], _now),
        isTrue,
      );
    });

    test('ignores mocked samples that already expired', () {
      expect(
        GeotagLockPolicy.containsMocked([
          _pos(accuracy: 5, ageSeconds: 1),
          _pos(accuracy: 5, ageSeconds: 45, isMocked: true),
        ], _now),
        isFalse,
      );
    });
  });
}
