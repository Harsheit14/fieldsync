import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/stored_file_entity.dart';
import '../../domain/exceptions/storage_exception.dart';
import '../../domain/services/storage_service.dart';

class StorageServiceImpl implements StorageService {
  static const _uuid = Uuid();

  @override
  Future<StoredFileEntity> saveFile(String sourcePath) async {
    try {
      final documentsDirectory =
          await getApplicationDocumentsDirectory();

      final imagesDirectory = Directory(
        path.join(
          documentsDirectory.path,
          'FieldSync',
          'surveys',
          'images',
        ),
      );

      if (!await imagesDirectory.exists()) {
        await imagesDirectory.create(recursive: true);
      }

      final extension = path.extension(sourcePath);

      final fileName = 'survey_${_uuid.v4()}$extension';

      final destinationPath = path.join(
        imagesDirectory.path,
        fileName,
      );

      final sourceFile = File(sourcePath);

      final storedFile = await sourceFile.copy(destinationPath);

      return StoredFileEntity(
        path: storedFile.path,
        fileName: fileName,
        sizeInBytes: await storedFile.length(),
        createdAt: DateTime.now(),
      );
    } catch (_) {
      throw const SaveFileException();
    }
  }

  @override
  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      throw const DeleteFileException();
    }
  }

  @override
  Future<StoredFileEntity?> readFile(String path) async {
    try {
      final file = File(path);

      if (!await file.exists()) {
        return null;
      }

      return StoredFileEntity(
        path: file.path,
        fileName: file.uri.pathSegments.last,
        sizeInBytes: await file.length(),
        createdAt: await file.lastModified(),
      );
    } catch (_) {
      throw const ReadFileException();
    }
  }
}