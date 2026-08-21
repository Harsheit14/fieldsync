import 'package:geolocator/geolocator.dart' hide LocationServiceDisabledException;

import '../../domain/entities/location_entity.dart';
import '../../domain/exceptions/location_exception.dart';
import '../../domain/services/location_service.dart';

class LocationServiceImpl implements LocationService {
  const LocationServiceImpl();

  @override
  Future<LocationEntity> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationServiceDisabledException();
    }

    final permission = await requestPermission();

    if (permission == LocationPermissionStatus.deniedForever) {
      throw const LocationPermissionDeniedForeverException();
    }

    if (permission == LocationPermissionStatus.denied) {
      throw const LocationPermissionDeniedException();
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LocationEntity(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  @override
  Future<bool> isLocationEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;

      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;

      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.denied;
    }
  }
}