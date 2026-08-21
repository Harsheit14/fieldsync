import '../entities/stored_file_entity.dart';
import '../repositories/storage_repository.dart';

class SaveFileUseCase {
  const SaveFileUseCase(this._repository);

  final StorageRepository _repository;

  Future<StoredFileEntity> call(String sourcePath) {
    return _repository.saveFile(sourcePath);
  }
}