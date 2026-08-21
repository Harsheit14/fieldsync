class StoredFileEntity {
  const StoredFileEntity({
    required this.path,
    required this.fileName,
    required this.sizeInBytes,
    required this.createdAt,
  });

  final String path;
  final String fileName;
  final int sizeInBytes;
  final DateTime createdAt;
}