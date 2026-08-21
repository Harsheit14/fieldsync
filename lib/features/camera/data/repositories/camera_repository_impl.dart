import '../../domain/entities/camera_image_entity.dart';
import '../../domain/repositories/camera_repository.dart';
import '../../domain/services/camera_service.dart';

class CameraRepositoryImpl implements CameraRepository {
  const CameraRepositoryImpl(this._cameraService);

  final CameraService _cameraService;

  @override
  Future<CameraImageEntity> captureImage() {
    return _cameraService.captureImage();
  }
}