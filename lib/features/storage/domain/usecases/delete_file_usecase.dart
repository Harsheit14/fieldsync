import '../repositories/storage_repository.dart';

class DeleteFileUseCase {
  const DeleteFileUseCase(this._repository);

  final StorageRepository _repository;

  Future<void> call(String path) {
    return _repository.deleteFile(path);
  }
}
