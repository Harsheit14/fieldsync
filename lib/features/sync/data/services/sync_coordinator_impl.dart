import 'dart:async';

import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';
import 'package:fieldsync/features/sync/domain/handlers/sync_handler.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';
import 'package:fieldsync/features/sync/domain/repositories/pending_operations_repository.dart';
import 'package:fieldsync/features/sync/domain/policies/retry_policy.dart';
import 'package:fieldsync/features/sync/domain/services/connectivity_service.dart';
import 'package:fieldsync/features/sync/domain/services/sync_coordinator.dart';

class SyncCoordinatorImpl implements SyncCoordinator {
  SyncCoordinatorImpl(
    this._connectivityService,
    this._pendingOperationsRepository,
    this._syncHandlers,
    this._retryPolicy,
    this._syncLogger,
  );

  final ConnectivityService _connectivityService;
  final PendingOperationsRepository _pendingOperationsRepository;
  final List<SyncHandler> _syncHandlers;
  final RetryPolicy _retryPolicy;
  final SyncLogger _syncLogger;

  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<PendingOperationEntity>>?
  _readyOperationsSubscription;

  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  Future<void>? _syncTask;
  Timer? _retryTimer;

  bool _isRunning = false;
  bool _stopRequested = false;
  bool _lastConnectivityState = false;

  /// After the configured retry budget is exhausted for a transient
  /// failure, the operation remains recoverable and starts a new retry
  /// cycle after this delay.
  static const Duration _retryCycleResetDelay = Duration(minutes: 1);

  Stream<bool> get statusChanges => _statusController.stream;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> start() async {
    if (_connectivitySubscription != null) {
      return;
    }

    _stopRequested = false;

    await _pendingOperationsRepository.resetProcessingOperations();

    await _log(
      SyncLogEventType.coordinatorStarted,
      'Sync coordinator started.',
    );

    _lastConnectivityState = await _connectivityService.isConnected();

    _readyOperationsSubscription = _pendingOperationsRepository
        .watchReadyOperations()
        .listen((operations) {
          if (operations.isEmpty || !_lastConnectivityState) {
            return;
          }

          unawaited(_runSynchronization());
        });

    _connectivitySubscription = _connectivityService
        .watchConnectivity()
        .skip(1)
        .listen(
          (isConnected) {
            unawaited(_handleConnectivityChange(isConnected));
          },
          onError: (_) {
            unawaited(_handleConnectivityChange(false));
          },
        );

    if (_lastConnectivityState) {
      unawaited(_runSynchronization());
    }
  }

  @override
  Future<void> stop() async {
    _stopRequested = true;

    _retryTimer?.cancel();
    _retryTimer = null;

    await _readyOperationsSubscription?.cancel();
    _readyOperationsSubscription = null;

    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;

    final syncTask = _syncTask;

    if (syncTask != null) {
      await syncTask;
    }

    await _log(
      SyncLogEventType.coordinatorStopped,
      'Sync coordinator stopped.',
    );
  }

  Future<void> _handleConnectivityChange(bool isConnected) async {
    if (isConnected == _lastConnectivityState) {
      return;
    }

    final wasOffline = !_lastConnectivityState;

    _lastConnectivityState = isConnected;

    if (!isConnected) {
      _stopRequested = true;

      _retryTimer?.cancel();
      _retryTimer = null;

      return;
    }

    _stopRequested = false;

    if (wasOffline) {
      await _runSynchronization();
    }
  }

  Future<void> _runSynchronization() async {
    if (_syncTask != null || _stopRequested || !_lastConnectivityState) {
      return;
    }

    _syncTask = _synchronize();

    try {
      await _syncTask;
    } finally {
      _syncTask = null;

      if (!_stopRequested && _lastConnectivityState) {
        await _scheduleNextRetry();
      }
    }
  }

  Future<void> _synchronize() async {
    _isRunning = true;
    _emitStatus();

    await _log(SyncLogEventType.syncStarted, 'Synchronization started.');

    try {
      final pendingOperations = await _pendingOperationsRepository
          .watchReadyOperations()
          .first;

      for (final operation in pendingOperations) {
        if (_stopRequested || !_lastConnectivityState) {
          break;
        }

        await _processOperation(operation);
      }
    } finally {
      _isRunning = false;
      _emitStatus();

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
    // ------------------------------------------------------------
    // SUCCESS
    // ------------------------------------------------------------
    if (result.success) {
      await _pendingOperationsRepository.markCompleted(operation.id);

      return;
    }

    // ------------------------------------------------------------
    // RETRYABLE FAILURE
    // ------------------------------------------------------------
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

      // ----------------------------------------------------------
      // RETRY BUDGET EXHAUSTED
      //
      // This is still a transient/recoverable failure.
      // Do NOT permanently mark the operation as failed.
      //
      // Start a fresh retry cycle after one minute.
      // ----------------------------------------------------------
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

    // ------------------------------------------------------------
    // PERMANENT FAILURE
    //
    // Examples:
    // - Invalid payload
    // - Unauthorized request
    // - HTTP 400
    // - HTTP 401
    // - HTTP 403
    // - HTTP 404
    // etc.
    //
    // These should remain permanently failed until explicitly
    // repaired/retried by the application.
    // ------------------------------------------------------------
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

  Future<void> _scheduleNextRetry() async {
    if (_stopRequested || !_lastConnectivityState) {
      return;
    }

    final nextScheduledOperation = await _pendingOperationsRepository
        .getNextScheduledOperation();

    final nextRetryAt = nextScheduledOperation?.nextRetryAt;

    if (nextRetryAt == null) {
      _retryTimer?.cancel();
      _retryTimer = null;
      return;
    }

    final delay = nextRetryAt.difference(DateTime.now());

    _retryTimer?.cancel();

    if (delay <= Duration.zero) {
      unawaited(_runSynchronization());
      return;
    }

    _retryTimer = Timer(delay, () {
      unawaited(_runSynchronization());
    });
  }

  String _resultMessage(SyncResult result) {
    return result.message ?? result.error?.toString() ?? _defaultFailureMessage;
  }

  String _noHandlerMessage(String entityType) {
    return 'No sync handler registered for $entityType.';
  }

  static const _defaultFailureMessage = 'Synchronization failed.';

  void _emitStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(_isRunning);
    }
  }

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
