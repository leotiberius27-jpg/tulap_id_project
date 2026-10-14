import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tulap_mobile/core/geo/location_fusion_engine.dart';

final _t0 = DateTime(2026, 10, 13, 12);
const _lat = -4.5559;
const _lng = 136.8930;

/// Geser koordinat sejauh [north]/[east] meter dari titik acuan.
Position _pos({
  double north = 0,
  double east = 0,
  required double accuracy,
  bool isMocked = false,
  double speed = 0,
}) {
  const r = 6371008.8;
  final dLat = north / r * 180 / math.pi;
  final dLng = east / (r * math.cos(_lat * math.pi / 180)) * 180 / math.pi;
  return Position(
    latitude: _lat + dLat,
    longitude: _lng + dLng,
    timestamp: _t0,
    accuracy: accuracy,
    altitude: 10,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: speed,
    speedAccuracy: 1,
    isMocked: isMocked,
  );
}

DateTime _at(int ms) => _t0.add(Duration(milliseconds: ms));

double _metersFromOrigin(Position p) =>
    Geolocator.distanceBetween(_lat, _lng, p.latitude, p.longitude);

void main() {
  group('LocationFusionEngine', () {
    test('ignores mocked and invalid samples', () {
      final e = LocationFusionEngine();
      expect(
        e.addSample(_pos(accuracy: 5, isMocked: true), observedAt: _at(0)),
        isFalse,
      );
      expect(e.addSample(_pos(accuracy: 0), observedAt: _at(0)), isFalse);
      expect(e.hasEstimate, isFalse);
    });

    test('an accurate fix is not dragged away by a coarse one', () {
      final e = LocationFusionEngine();
      e.addSample(_pos(accuracy: 5), observedAt: _at(0));
      e.addSample(_pos(north: 40, accuracy: 40), observedAt: _at(1000));
      // Bobot 1/σ² -> fix ±40 m hanya menggeser sedikit.
      expect(_metersFromOrigin(e.estimate!), lessThan(3));
      expect(e.estimate!.accuracy, lessThan(10));
    });

    test('stationary fixes converge tighter than any single fix', () {
      final e = LocationFusionEngine();
      // Noise ±8 m di sekitar titik acuan, berdiri diam 6 detik.
      const offsets = [6.0, -5.0, 4.0, -7.0, 3.0, -2.0];
      for (var i = 0; i < offsets.length; i++) {
        e.addSample(
          _pos(north: offsets[i], east: -offsets[i] / 2, accuracy: 10),
          observedAt: _at(i * 1000),
        );
      }
      expect(_metersFromOrigin(e.estimate!), lessThan(4));
      final acc = e.accuracyAt(_at(5000))!;
      expect(acc, lessThan(10));
      // ...tapi tidak mengklaim lebih baik dari 0.6 × fix mentah terbaik.
      expect(acc, greaterThanOrEqualTo(6));
    });

    test('uncertainty grows with age so old fixes are never "accurate"', () {
      final e = LocationFusionEngine();
      e.addSample(_pos(accuracy: 5), observedAt: _at(0));
      expect(e.accuracyAt(_at(0)), closeTo(5, 0.01));
      // 20 detik tanpa fix baru -> +30 m (jalan kaki 1.5 m/s).
      expect(e.accuracyAt(_at(20000)), closeTo(35, 0.01));
      expect(e.ageAt(_at(20000)), const Duration(seconds: 20));
    });

    test('rejects a physically impossible jump (multipath glitch)', () {
      final e = LocationFusionEngine();
      e.addSample(_pos(accuracy: 5), observedAt: _at(0));
      e.addSample(_pos(accuracy: 5), observedAt: _at(1000));
      final accepted = e.addSample(
        _pos(north: 800, accuracy: 10),
        observedAt: _at(2000),
      );
      expect(accepted, isFalse);
      expect(_metersFromOrigin(e.estimate!), lessThan(3));
    });

    test('resets after a sustained jump (device really moved)', () {
      final e = LocationFusionEngine();
      e.addSample(_pos(accuracy: 5), observedAt: _at(0));
      for (var i = 1; i <= 3; i++) {
        e.addSample(_pos(north: 2000, accuracy: 8), observedAt: _at(i * 500));
      }
      expect(_metersFromOrigin(e.estimate!), closeTo(2000, 5));
    });

    test('a stale last-known anchor is overtaken by a live fix elsewhere', () {
      final e = LocationFusionEngine();
      // Last known ±5 m berumur 10 menit (mis. di rumah).
      e.addSample(_pos(accuracy: 5), observedAt: _at(0));
      // Fix live di lapangan 600 m dari situ, ±20 m.
      final accepted = e.addSample(
        _pos(north: 600, accuracy: 20),
        observedAt: _at(10 * 60 * 1000),
      );
      expect(accepted, isTrue);
      expect(_metersFromOrigin(e.estimate!), closeTo(600, 2));
    });

    test('drops samples that arrive out of order', () {
      final e = LocationFusionEngine();
      e.addSample(_pos(accuracy: 5), observedAt: _at(5000));
      expect(
        e.addSample(_pos(north: 30, accuracy: 3), observedAt: _at(1000)),
        isFalse,
      );
      expect(e.sampleCount, 1);
    });
  });
}
