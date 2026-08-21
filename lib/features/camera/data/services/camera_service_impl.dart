import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/camera_image_entity.dart';
import '../../domain/exceptions/camera_exception.dart';
import '../../domain/services/camera_service.dart';

class CameraServiceImpl implements CameraService {
  CameraServiceImpl({
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<CameraImageEntity> captureImage() async {
    try {
      ImageSource source = ImageSource.camera;

      if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;

        debugPrint(
          'iOS physical device: ${iosInfo.isPhysicalDevice}',
        );

        if (!iosInfo.isPhysicalDevice) {
          source = ImageSource.gallery;

          debugPrint(
            'iOS Simulator detected. Using gallery.',
          );
        } else {
          debugPrint(
            'Physical iPhone detected. Using camera.',
          );
        }
      }

      debugPrint('ImagePicker source: $source');

      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image == null) {
        throw const CameraCancelledException();
      }

      debugPrint('Image selected: ${image.path}');

      final file = File(image.path);

      return CameraImageEntity(
        path: image.path,
        fileName: image.name,
        sizeInBytes: await file.length(),
        capturedAt: DateTime.now(),
      );
    } on CameraException {
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Image picker error: $error');
      debugPrint('Stack trace: $stackTrace');

      throw const CameraCaptureFailedException();
    }
  }
}