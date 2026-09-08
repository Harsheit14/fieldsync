import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/repositories/pending_operations_repository.dart';

class EnqueuePendingOperationUseCase {
  EnqueuePendingOperationUseCase(this._repository);

  final PendingOperationsRepository _repository;

  Future<void> execute(PendingOperationEntity operation) {
    return _repository.enqueueOperation(operation);
  }
}
