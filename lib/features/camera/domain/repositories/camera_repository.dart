import '../entities/camera_image_entity.dart';

abstract class CameraRepository {
  Future<CameraImageEntity> captureImage();
}