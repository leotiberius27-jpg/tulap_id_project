/// Re-exported so callers of `checkAndRequestPermissions()` can catch
/// these two by name from this single file, without also importing
/// `package:geolocator/geolocator.dart` directly. NOT redefined here -
/// `geolocator_platform_interface` already ships both
/// `LocationServiceDisabledException` and `PermissionDeniedException`
/// with the exact same meaning `checkAndRequestPermissions()` needs.
/// Defining our own duplicate classes with the same names caused a real
/// `ambiguous_import` compile error (caught by `flutter analyze` before
/// this ever reached a device) - reusing the package's own types instead.
export 'package:geolocator/geolocator.dart'
    show LocationServiceDisabledException, PermissionDeniedException;

/// LocationPermissionDeniedForeverException
/// ----------------------------------------------------------------------
/// The one case `geolocator` does NOT model as its own exception type -
/// it only exposes `LocationPermission.deniedForever` as an enum value.
/// `checkAndRequestPermissions()` throws this so callers can tell
/// "denied, ask again" (`PermissionDeniedException`) apart from "denied
/// permanently, only Settings can fix this" without inspecting message
/// strings.
class LocationPermissionDeniedForeverException implements Exception {
  const LocationPermissionDeniedForeverException();

  @override
  String toString() =>
      'Izin lokasi ditolak permanen. Aktifkan lewat Pengaturan > Aplikasi > Tulap.id > Izin.';
}
