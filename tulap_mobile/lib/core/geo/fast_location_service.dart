import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

import 'reverse_geocoder.dart';

enum LocationTier {
  none,
  fastInitial,
  freshRefining,
  verified,
}

class FastLocationData {
  final LocationTier tier;
  final Position? position;
  final double? latitude;
  final double? longitude;
  final double accuracy;
  final double? altitude;
  final double? heading;
  final String? address;
  final DateTime? timestamp;
  final bool isMocked;

  const FastLocationData({
    required this.tier,
    this.position,
    this.latitude,
    this.longitude,
    required this.accuracy,
    this.altitude,
    this.heading,
    this.address,
    this.timestamp,
    required this.isMocked,
  });
}

class FastLocationService {
  FastLocationService._();

  static final FastLocationService _instance = FastLocationService._();
  static FastLocationService get instance => _instance;

  final List<Position> _recentCandidates = [];
  final int _maxHistory = 8;

  Position? latestCandidatePosition;
  ReverseGeocoder? _reverseGeocoder;

  StreamSubscription<Position>? _gpsSubscription;
  bool _isRunning = false;

  void setReverseGeocoder(ReverseGeocoder geocoder) {
    _reverseGeocoder = geocoder;
  }

  Future<FastLocationData> getAtomicCaptureLocation() async {
    final candidate = latestCandidatePosition;
    if (candidate != null) {
      return _buildDataFromPosition(candidate);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 8),
      );

      final filtered = _filterAndSmooth(position);
      if (filtered != null) {
        latestCandidatePosition = filtered;
        _pushCandidate(filtered);
        return _buildDataFromPosition(filtered);
      }
    } catch (_) {
      // ignore
    }

    return FastLocationData(
      tier: LocationTier.none,
      position: null,
      latitude: null,
      longitude: null,
      accuracy: 9999.0,
      altitude: null,
      heading: null,
      address: null,
      timestamp: DateTime.now(),
      isMocked: false,
    );
  }

  Future<void> startActiveCameraStream({
    required void Function(FastLocationData data) onLocationUpdate,
    Position? initialCandidate,
  }) async {
    if (_isRunning) return;

    _isRunning = true;

    if (initialCandidate != null) {
      latestCandidatePosition = initialCandidate;
      _pushCandidate(initialCandidate);
      onLocationUpdate(_buildDataFromPosition(initialCandidate));
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return;
    }

    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
      ),
    ).listen((position) async {
      final filtered = _filterAndSmooth(position);
      if (filtered == null) return;

      latestCandidatePosition = filtered;
      _pushCandidate(filtered);

      final data = _buildDataFromPosition(filtered);
      if (_reverseGeocoder != null) {
        try {
          final addr = await _reverseGeocoder!.reverseGeocode(
            latitude: filtered.latitude,
            longitude: filtered.longitude,
          );
          onLocationUpdate(
            FastLocationData(
              tier: data.tier,
              position: data.position,
              latitude: data.latitude,
              longitude: data.longitude,
              accuracy: data.accuracy,
              altitude: data.altitude,
              heading: data.heading,
              address: addr,
              timestamp: data.timestamp,
              isMocked: data.isMocked,
            ),
          );
          return;
        } catch (_) {
          // ignore reverse geocode failures here; fallback to raw data
        }
      }

      onLocationUpdate(data);
    });
  }

  void stop() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _isRunning = false;
  }

  Position? _filterAndSmooth(Position raw) {
    if (raw.isMocked) return null;
    if (raw.accuracy > 80.0) return null;

    final age = DateTime.now().difference(raw.timestamp).inSeconds;
    if (age > 25) return null;

    if (latestCandidatePosition != null) {
      final last = latestCandidatePosition!;
      final distance = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        raw.latitude,
        raw.longitude,
      );

      final elapsedSeconds = max(
        1,
        raw.timestamp.difference(last.timestamp).inMilliseconds ~/ 1000,
      );
      final speed = distance / elapsedSeconds;

      if (speed > 40.0) {
        return null;
      }

      if (distance > 100.0 && raw.accuracy < 25.0) {
        return null;
      }
    }

    final window = List<Position>.from(_recentCandidates);
    window.add(raw);

    if (window.length >= 2) {
      final latitudes = window.map((p) => p.latitude).toList();
      final longitudes = window.map((p) => p.longitude).toList();
      final accuracies = window.map((p) => p.accuracy).toList();

      final filteredLat = _weightedAverage(latitudes, accuracies);
      final filteredLon = _weightedAverage(longitudes, accuracies);
      final filteredAcc = _average(accuracies);

      final filtered = Position(
        latitude: filteredLat,
        longitude: filteredLon,
        timestamp: raw.timestamp,
        accuracy: filteredAcc,
        altitude: raw.altitude,
        heading: raw.heading,
        speed: raw.speed,
        speedAccuracy: raw.speedAccuracy,
        floor: raw.floor,
        isMocked: false,
      );
      return filtered;
    }

    return raw;
  }

  void _pushCandidate(Position pos) {
    _recentCandidates.add(pos);
    if (_recentCandidates.length > _maxHistory) {
      _recentCandidates.removeAt(0);
    }
  }

  FastLocationData _buildDataFromPosition(Position position) {
    final tier = _determineTier(position);

    return FastLocationData(
      tier: tier,
      position: position,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      address: null,
      timestamp: position.timestamp,
      isMocked: position.isMocked,
    );
  }

  LocationTier _determineTier(Position p) {
    if (p.accuracy <= 8.0 && !p.isMocked) return LocationTier.verified;
    if (p.accuracy <= 25.0 && !p.isMocked) return LocationTier.freshRefining;
    if (p.accuracy <= 60.0 && !p.isMocked) return LocationTier.fastInitial;
    return LocationTier.none;
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _weightedAverage(List<double> values, List<double> weights) {
    if (values.isEmpty) return 0.0;
    final paired = List.generate(values.length, (i) => MapEntry(values[i], weights[i]));
    final inverted = paired
        .map((e) => MapEntry(e.key, 1 / (e.value + 0.0001)))
        .toList();
    final numerator = inverted
        .map((e) => e.key * e.value)
        .reduce((a, b) => a + b);
    final denominator = inverted
        .map((e) => e.value)
        .reduce((a, b) => a + b);
    return denominator == 0 ? values.first : numerator / denominator;
  }
}
