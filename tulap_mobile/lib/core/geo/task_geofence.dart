import 'dart:math';

/// Task geofence status for location-aware field tasks.
///
/// This utility keeps field evidence honest: a task can have a target GPS
/// coordinate and a radius within which evidence is considered valid. The check
/// is deterministic and intentionally simple so it can be reused in the camera,
/// task validation, and verification workflows.
class TaskGeofenceResult {
  final bool isWithinRadius;
  final double distanceMeters;
  final double radiusMeters;

  const TaskGeofenceResult({
    required this.isWithinRadius,
    required this.distanceMeters,
    required this.radiusMeters,
  });
}

class TaskGeofence {
  const TaskGeofence();

  TaskGeofenceResult check({
    required double? taskLatitude,
    required double? taskLongitude,
    required double? deviceLatitude,
    required double? deviceLongitude,
    required double radiusMeters,
  }) {
    final hasTaskPoint = taskLatitude != null && taskLongitude != null;
    final hasDevicePoint = deviceLatitude != null && deviceLongitude != null;

    if (!hasTaskPoint || !hasDevicePoint) {
      return TaskGeofenceResult(
        isWithinRadius: true,
        distanceMeters: 0,
        radiusMeters: radiusMeters,
      );
    }

    final distance = _haversineMeters(
      lat1: taskLatitude,
      lon1: taskLongitude,
      lat2: deviceLatitude,
      lon2: deviceLongitude,
    );

    return TaskGeofenceResult(
      isWithinRadius: distance <= radiusMeters,
      distanceMeters: distance,
      radiusMeters: radiusMeters,
    );
  }

  double _haversineMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusMeters = 6371000.0;
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;
}
