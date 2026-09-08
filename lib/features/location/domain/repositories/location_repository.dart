import '../entities/location_entity.dart';
import '../services/location_service.dart';

abstract class LocationRepository {
  Future<LocationEntity> getCurrentLocation();

  Future<bool> isLocationEnabled();

  Future<LocationPermissionStatus> requestPermission();
}