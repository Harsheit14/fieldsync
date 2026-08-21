import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/storage_repository_impl.dart';
import '../../data/services/storage_service_impl.dart';
import '../../domain/repositories/storage_repository.dart';
import '../../domain/services/storage_service.dart';
import '../../domain/usecases/delete_file_usecase.dart';
import '../../domain/usecases/read_file_usecase.dart';
import '../../domain/usecases/save_file_usecase.dart';

final storageServiceProvider =
    Provider<StorageService>(
  (ref) => StorageServiceImpl(),
);

final storageRepositoryProvider =
    Provider<StorageRepository>(
  (ref) => StorageRepositoryImpl(
    ref.watch(storageServiceProvider),
  ),
);

final saveFileUseCaseProvider =
    Provider<SaveFileUseCase>(
  (ref) => SaveFileUseCase(
    ref.watch(storageRepositoryProvider),
  ),
);

final readFileUseCaseProvider =
    Provider<ReadFileUseCase>(
  (ref) => ReadFileUseCase(
    ref.watch(storageRepositoryProvider),
  ),
);

final deleteFileUseCaseProvider =
    Provider<DeleteFileUseCase>(
  (ref) => DeleteFileUseCase(
    ref.watch(storageRepositoryProvider),
  ),
);