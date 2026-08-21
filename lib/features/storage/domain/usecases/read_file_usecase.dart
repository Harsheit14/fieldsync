import '../entities/stored_file_entity.dart';
import '../repositories/storage_repository.dart';

class ReadFileUseCase {
  const ReadFileUseCase(this._repository);

  final StorageRepository _repository;

  Future<StoredFileEntity?> call(String path) {
    return _repository.readFile(path);
  }
}