import 'package:fieldsync/features/storage/domain/entities/stored_file_entity.dart';
import 'package:fieldsync/features/storage/domain/usecases/save_file_usecase.dart';

import 'capture_image_usecase.dart';

class CaptureAndStoreImageUseCase {
  const CaptureAndStoreImageUseCase(
    this._captureImageUseCase,
    this._saveFileUseCase,
  );

  final CaptureImageUseCase _captureImageUseCase;
  final SaveFileUseCase _saveFileUseCase;

  Future<StoredFileEntity> call() async {
    final image = await _captureImageUseCase();

    return _saveFileUseCase(
      image.path,
    );
  }
}