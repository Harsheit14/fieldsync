import '../entities/location_entity.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
}

abstract class LocationService {
  Future<LocationEntity> getCurrentLocation();

  Future<bool> isLocationEnabled();

  Future<LocationPermissionStatus> requestPermission();
}