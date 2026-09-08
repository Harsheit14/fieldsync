class CameraImageEntity {
  const CameraImageEntity({
    required this.path,
    required this.fileName,
    required this.sizeInBytes,
    required this.capturedAt,
  });

  final String path;
  final String fileName;
  final int sizeInBytes;
  final DateTime capturedAt;
}