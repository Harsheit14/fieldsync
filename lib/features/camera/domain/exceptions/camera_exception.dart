class CameraException implements Exception {
  const CameraException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CameraPermissionDeniedException extends CameraException {
  const CameraPermissionDeniedException()
      : super('Camera permission denied.');
}

class CameraCaptureFailedException extends CameraException {
  const CameraCaptureFailedException()
      : super('Failed to capture image.');
}

class CameraCancelledException extends CameraException {
  const CameraCancelledException()
      : super('Image capture was cancelled.');
}