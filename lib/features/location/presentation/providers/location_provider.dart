import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/location_repository_impl.dart';
import '../../data/services/location_service_impl.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/services/location_service.dart';
import '../../domain/usecases/get_current_location_usecase.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationServiceImpl();
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(
    ref.watch(locationServiceProvider),
  );
});

final getCurrentLocationUseCaseProvider =
    Provider<GetCurrentLocationUseCase>((ref) {
  return GetCurrentLocationUseCase(
    ref.watch(locationRepositoryProvider),
  );
});