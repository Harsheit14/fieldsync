import '../entities/camera_image_entity.dart';
import '../repositories/camera_repository.dart';

class CaptureImageUseCase {
  const CaptureImageUseCase(this._repository);

  final CameraRepository _repository;

  Future<CameraImageEntity> call() {
    return _repository.captureImage();
  }
}