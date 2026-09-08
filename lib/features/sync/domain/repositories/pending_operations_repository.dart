import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';

abstract class PendingOperationsRepository {
  Future<void> enqueueOperation(PendingOperationEntity operation);

  Stream<List<PendingOperationEntity>> watchReadyOperations();

  Future<PendingOperationEntity?> getNextScheduledOperation();

  Future<void> resetProcessingOperations();

  Future<void> markProcessing(String id);

  Future<void> markRetryScheduled(
    String id,
    int retryCount,
    DateTime nextRetryAt, {
    String? errorMessage,
  });

  Future<void> markCompleted(String id);

  Future<void> markFailed(String id, String errorMessage);

  Future<int> clearCompletedOperations();
}