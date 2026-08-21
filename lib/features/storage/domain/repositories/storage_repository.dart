import '../entities/stored_file_entity.dart';

abstract class StorageRepository {
  Future<StoredFileEntity> saveFile(String sourcePath);

  Future<StoredFileEntity?> readFile(String path);

  Future<void> deleteFile(String path);
}