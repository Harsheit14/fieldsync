import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';
import 'package:fieldsync/features/sync/domain/handlers/sync_handler.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';
import 'package:fieldsync/features/sync/domain/policies/retry_policy.dart';
import 'package:fieldsync/features/sync/domain/repositories/pending_operations_repository.dart';
import 'package:fieldsync/features/sync/domain/services/synchronization_service.dart';

class SynchronizationServiceImpl implements SynchronizationService {
  SynchronizationServiceImpl(
    this._pendingOperationsRepository,
    this._syncHandlers,
    this._retryPolicy,
    this._syncLogger,
  );

  final PendingOperationsRepository _pendingOperationsRepository;
  final List<SyncHandler> _syncHandlers;
  final RetryPolicy _retryPolicy;
  final SyncLogger _syncLogger;

  static const Duration _retryCycleResetDelay = Duration(minutes: 1);

  @override
  Future<void> synchronizeOnce() async {
    await _log(SyncLogEventType.syncStarted, 'Synchronization started.');

    try {
      final pendingOperations = await _pendingOperationsRepository
          .watchReadyOperations()
          .first;

      for (final operation in pendingOperations) {
        await _processOperation(operation);
      }
    } finally {
      await _log(SyncLogEventType.syncCompleted, 'Synchronization completed.');
    }
  }

  Future<void> _processOperation(PendingOperationEntity operation) async {
    SyncHandler? handler;

    for (final candidate in _syncHandlers) {
      if (candidate.supports(operation.entityType)) {
        handler = candidate;
        break;
      }
    }

    if (handler == null) {
      final message = _noHandlerMessage(operation.entityType);

      await _pendingOperationsRepository.markFailed(operation.id, message);

      await _log(SyncLogEventType.syncFailed, message, operation: operation);

      return;
    }

    await _pendingOperationsRepository.markProcessing(operation.id);

    await _log(
      SyncLogEventType.processingStarted,
      'Processing synchronization operation.',
      operation: operation,
    );

    try {
      final result = await handler.process(operation);

      await _applyResult(operation, result);
    } finally {
      await _log(
        SyncLogEventType.processingFinished,
        'Processing synchronization operation finished.',
        operation: operation,
      );
    }
  }

  Future<void> _applyResult(
    PendingOperationEntity operation,
    SyncResult result,
  ) async {
    if (result.success) {
      await _pendingOperationsRepository.markCompleted(operation.id);

      return;
    }

    if (result.retryable) {
      if (_retryPolicy.canRetry(operation.retryCount, result)) {
        final retryCount = operation.retryCount + 1;

        final nextRetryAt = DateTime.now().add(
          _retryPolicy.nextDelay(retryCount),
        );

        await _pendingOperationsRepository.markRetryScheduled(
          operation.id,
          retryCount,
          nextRetryAt,
          errorMessage: _resultMessage(result),
        );

        await _log(
          SyncLogEventType.retryScheduled,
          'Synchronization retry scheduled.',
          operation: operation,
          metadata: {
            'retryCount': retryCount,
            'nextRetryAt': nextRetryAt.toIso8601String(),
          },
        );

        return;
      }

      final nextRetryAt = DateTime.now().add(_retryCycleResetDelay);

      await _pendingOperationsRepository.markRetryScheduled(
        operation.id,
        0,
        nextRetryAt,
        errorMessage: _resultMessage(result),
      );

      await _log(
        SyncLogEventType.retryScheduled,
        'Retry budget exhausted; operation remains recoverable.',
        operation: operation,
        metadata: {
          'retryCount': operation.retryCount,
          'retryCycleReset': true,
          'nextRetryAt': nextRetryAt.toIso8601String(),
        },
      );

      return;
    }

    await _pendingOperationsRepository.markFailed(
      operation.id,
      _resultMessage(result),
    );

    await _log(
      SyncLogEventType.syncFailed,
      'Synchronization failed permanently.',
      operation: operation,
      metadata: {'retryCount': operation.retryCount, 'retryable': false},
    );
  }

  String _resultMessage(SyncResult result) {
    return result.message ?? result.error?.toString() ?? _defaultFailureMessage;
  }

  String _noHandlerMessage(String entityType) {
    return 'No sync handler registered for $entityType.';
  }

  static const _defaultFailureMessage = 'Synchronization failed.';

  Future<void> _log(
    SyncLogEventType eventType,
    String message, {
    PendingOperationEntity? operation,
    Map<String, Object?>? metadata,
  }) {
    return _syncLogger.log(
      SyncLogEntry(
        timestamp: DateTime.now(),
        operationId: operation?.id,
        entityType: operation?.entityType,
        entityId: operation?.entityId,
        eventType: eventType,
        message: message,
        metadata: metadata,
      ),
    );
  }
}
