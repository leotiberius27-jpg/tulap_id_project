/// Task geofence status for location-aware field tasks.
///
/// This utility keeps the app's field evidence logic honest: a task can have
/// a target GPS coordinate and a radius within which evidence is considered
/// valid. The check is intentionally simple and deterministic so it can be
/// reused in camera capture, task validation, and verification workflows.
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
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        (0.5 - (dLat / 2).cos()) +
        (0.5 - (dLon / 2).cos()) *
            (1 - (dLat / 2).cos()) *
            (1 - (dLon / 2).cos());

    final c = 2 * (a.sqrt().asin());
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180.0;
}
