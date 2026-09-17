import 'package:flutter/foundation.dart';
import '../../../../core/geo/reverse_geocoder.dart';
import '../../../geotag_camera/domain/usecases/validate_location_integrity.dart';

enum LocationCheckStatus { checking, checked, error }

class LocationState {
  final LocationCheckStatus status;
  final LocationIntegrityStatus? integrityStatus;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final String? formattedAddress;
  final String? errorMessage;

  const LocationState({
    this.status = LocationCheckStatus.checking,
    this.integrityStatus,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.formattedAddress,
    this.errorMessage,
  });
}

class LocationController extends ChangeNotifier {
  final ValidateLocationIntegrity _validateLocationIntegrity;
  final ReverseGeocoder? _reverseGeocoder;

  LocationState _state = const LocationState();
  LocationState get state => _state;

  LocationController({
    required ValidateLocationIntegrity validateLocationIntegrity,
    ReverseGeocoder? reverseGeocoder,
  }) : _validateLocationIntegrity = validateLocationIntegrity,
       _reverseGeocoder = reverseGeocoder {
    checkLocation();
  }

  void _update(LocationState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> checkLocation() async {
    _update(const LocationState(status: LocationCheckStatus.checking));

    final result = await _validateLocationIntegrity();

    await result.fold(
      (failure) async => _update(
        LocationState(
          status: LocationCheckStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (checkResult) async {
        String? address;
        if (_reverseGeocoder != null) {
          try {
            address = await _reverseGeocoder.reverseGeocode(
              latitude: checkResult.latitude,
              longitude: checkResult.longitude,
            );
          } catch (_) {
            address = null;
          }
        }

        _update(
          LocationState(
            status: LocationCheckStatus.checked,
            integrityStatus: checkResult.status,
            latitude: checkResult.latitude,
            longitude: checkResult.longitude,
            accuracyMeters: checkResult.accuracyMeters,
            formattedAddress: address,
          ),
        );
      },
    );
  }
}
