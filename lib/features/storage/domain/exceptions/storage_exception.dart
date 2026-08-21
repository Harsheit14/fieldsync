class StorageException implements Exception {
  const StorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SaveFileException extends StorageException {
  const SaveFileException()
      : super('Failed to save file.');
}

class ReadFileException extends StorageException {
  const ReadFileException()
      : super('Failed to read file.');
}

class DeleteFileException extends StorageException {
  const DeleteFileException()
      : super('Failed to delete file.');
}