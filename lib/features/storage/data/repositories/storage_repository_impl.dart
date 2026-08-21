import '../../domain/entities/stored_file_entity.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/services/storage_service.dart';

class StorageRepositoryImpl implements StorageRepository {
  const StorageRepositoryImpl(
    this._storageService,
  );

  final StorageService _storageService;

  @override
  Future<StoredFileEntity> saveFile(
    String sourcePath,
  ) {
    return _storageService.saveFile(sourcePath);
  }

  @override
  Future<void> deleteFile(
    String path,
  ) {
    return _storageService.deleteFile(path);
  }

  @override
  Future<StoredFileEntity?> readFile(
    String path,
  ) {
    return _storageService.readFile(path);
  }
}