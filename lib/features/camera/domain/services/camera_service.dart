import '../entities/camera_image_entity.dart';

abstract class CameraService {
  Future<CameraImageEntity> captureImage();
}