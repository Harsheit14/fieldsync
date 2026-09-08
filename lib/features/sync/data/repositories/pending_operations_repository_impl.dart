import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/mappers/pending_operation_mapper.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';
import 'package:fieldsync/features/sync/domain/repositories/pending_operations_repository.dart';

class PendingOperationsRepositoryImpl implements PendingOperationsRepository {
  PendingOperationsRepositoryImpl(this._dao, this._mapper, this._syncLogger);

  final PendingOperationsDao _dao;
  final PendingOperationMapper _mapper;
  final SyncLogger _syncLogger;

  @override
  Future<void> enqueueOperation(PendingOperationEntity operation) async {
    await _dao.enqueue(_mapper.toCompanion(operation));

    await _syncLogger.log(
      SyncLogEntry(
        timestamp: DateTime.now(),
        operationId: operation.id,
        entityType: operation.entityType,
        entityId: operation.entityId,
        eventType: SyncLogEventType.operationQueued,
        message: 'Operation queued for synchronization.',
        metadata: {'operationType': operation.operationType.name},
      ),
    );
  }

  @override
  Stream<List<PendingOperationEntity>> watchReadyOperations() {
    return _dao.watchReadyOperations().map(
      (operations) => operations.map(_mapper.toEntity).toList(),
    );
  }

  @override
  Future<PendingOperationEntity?> getNextScheduledOperation() async {
    final operation = await _dao.getNextScheduledOperation();

    return operation == null ? null : _mapper.toEntity(operation);
  }

  @override
  Future<void> resetProcessingOperations() async {
    await _dao.resetProcessingOperations();
  }

  @override
  Future<void> markProcessing(String id) async {
    await _dao.markProcessing(id);
  }

  @override
  Future<void> markRetryScheduled(
    String id,
    int retryCount,
    DateTime nextRetryAt, {
    String? errorMessage,
  }) async {
    await _dao.markRetryScheduled(
      id,
      retryCount,
      nextRetryAt,
      errorMessage: errorMessage,
    );
  }

  @override
  Future<void> markCompleted(String id) async {
    await _dao.markCompleted(id);
  }

  @override
  Future<void> markFailed(String id, String errorMessage) async {
    await _dao.markFailed(id, errorMessage);
  }

  @override
  Future<int> clearCompletedOperations() {
    return _dao.clearCompletedOperations();
  }
}
