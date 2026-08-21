import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldsync/features/storage/presentation/providers/storage_provider.dart';

import '../../data/repositories/camera_repository_impl.dart';
import '../../data/services/camera_service_impl.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/usecases/capture_and_store_image_usecase.dart';
import '../../domain/usecases/capture_image_usecase.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraServiceImpl();
});

final cameraRepositoryProvider = Provider<CameraRepository>((ref) {
  return CameraRepositoryImpl(
    ref.watch(cameraServiceProvider),
  );
});

final captureImageUseCaseProvider = Provider<CaptureImageUseCase>((ref) {
  return CaptureImageUseCase(
    ref.watch(cameraRepositoryProvider),
  );
});

final captureAndStoreImageUseCaseProvider =
    Provider<CaptureAndStoreImageUseCase>((ref) {
  return CaptureAndStoreImageUseCase(
    ref.watch(captureImageUseCaseProvider),
    ref.watch(saveFileUseCaseProvider),
  );
});