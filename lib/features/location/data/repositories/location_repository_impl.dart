import '../../domain/entities/location_entity.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/services/location_service.dart';

class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._locationService);

  final LocationService _locationService;

  @override
  Future<LocationEntity> getCurrentLocation() {
    return _locationService.getCurrentLocation();
  }

  @override
  Future<bool> isLocationEnabled() {
    return _locationService.isLocationEnabled();
  }

  @override
  Future<LocationPermissionStatus> requestPermission() {
    return _locationService.requestPermission();
  }
}