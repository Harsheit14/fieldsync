import 'dart:async';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';
import 'package:fieldsync/features/sync/domain/repositories/pending_operations_repository.dart';
import 'package:fieldsync/features/sync/domain/services/connectivity_service.dart';
import 'package:fieldsync/features/sync/domain/services/synchronization_service.dart';
import 'package:fieldsync/features/sync/domain/services/sync_coordinator.dart';

class SyncCoordinatorImpl implements SyncCoordinator {
  SyncCoordinatorImpl(
    this._connectivityService,
    this._pendingOperationsRepository,
    this._synchronizationService,
    this._syncLogger,
  );

  final ConnectivityService _connectivityService;
  final PendingOperationsRepository _pendingOperationsRepository;
  final SynchronizationService _synchronizationService;
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

  Stream<bool> get statusChanges => _statusController.stream;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> syncNow() async {
    if (_stopRequested || !_lastConnectivityState) {
      return;
    }

    await _runSynchronization();
  }

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

    try {
      await _synchronizationService.synchronizeOnce();
    } finally {
      _isRunning = false;
      _emitStatus();
    }
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

  void _emitStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(_isRunning);
    }
  }

  Future<void> _log(SyncLogEventType eventType, String message) {
    return _syncLogger.log(
      SyncLogEntry(
        timestamp: DateTime.now(),
        eventType: eventType,
        message: message,
      ),
    );
  }
}
