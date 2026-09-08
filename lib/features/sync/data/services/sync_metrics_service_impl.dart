import 'dart:async';

import 'package:fieldsync/core/database/app_database.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';
import 'package:fieldsync/features/sync/domain/metrics/sync_metrics.dart';
import 'package:fieldsync/features/sync/domain/services/sync_metrics_service.dart';

/// Calculates metrics from local state and logs without affecting sync work.
class SyncMetricsServiceImpl implements SyncMetricsService {
  SyncMetricsServiceImpl(this._database, this._syncLogger);

  final AppDatabase _database;
  final SyncLogger _syncLogger;

  @override
  Future<SyncMetrics> calculate() async {
    final results = await Future.wait<Object>([
      _database.select(_database.pendingOperations).get(),
      _syncLogger.watchLogs().first,
    ]);

    return _calculate(
      results[0] as List<PendingOperation>,
      results[1] as List<SyncLogEntry>,
    );
  }

  @override
  Stream<SyncMetrics> watchMetrics() {
    return Stream<SyncMetrics>.multi((controller) {
      List<PendingOperation>? operations;
      List<SyncLogEntry>? logs;

      void emitIfReady() {
        if (operations == null || logs == null) {
          return;
        }
        controller.add(_calculate(operations!, logs!));
      }

      final operationsSubscription = _database
          .select(_database.pendingOperations)
          .watch()
          .listen((value) {
            operations = value;
            emitIfReady();
          }, onError: controller.addError);
      final logsSubscription = _syncLogger.watchLogs().listen((value) {
        logs = value;
        emitIfReady();
      }, onError: controller.addError);

      controller.onCancel = () async {
        await operationsSubscription.cancel();
        await logsSubscription.cancel();
      };
    });
  }

  SyncMetrics _calculate(
    List<PendingOperation> operations,
    List<SyncLogEntry> logs,
  ) {
    final pendingCount = _countByStatus(
      operations,
      PendingOperationStatus.pending,
    );
    final processingCount = _countByStatus(
      operations,
      PendingOperationStatus.processing,
    );
    final completedCount = _countByStatus(
      operations,
      PendingOperationStatus.completed,
    );
    final failedCount = _countByStatus(
      operations,
      PendingOperationStatus.failed,
    );
    final retryScheduledCount = _countByStatus(
      operations,
      PendingOperationStatus.retryScheduled,
    );
    final terminalCount = completedCount + failedCount;
    final totalRetryCount = operations.fold<int>(
      0,
      (total, operation) => total + operation.retryCount,
    );

    return SyncMetrics(
      queueSize: pendingCount + processingCount + retryScheduledCount,
      pendingCount: pendingCount,
      processingCount: processingCount,
      completedCount: completedCount,
      failedCount: failedCount,
      retryScheduledCount: retryScheduledCount,
      successRate: terminalCount == 0 ? 0 : completedCount / terminalCount,
      failureRate: terminalCount == 0 ? 0 : failedCount / terminalCount,
      averageSyncDuration: _averageSyncDuration(logs),
      averageRetryCount: operations.isEmpty
          ? 0
          : totalRetryCount / operations.length,
    );
  }

  int _countByStatus(
    List<PendingOperation> operations,
    PendingOperationStatus status,
  ) {
    return operations
        .where((operation) => operation.status == status.name)
        .length;
  }

  Duration _averageSyncDuration(List<SyncLogEntry> logs) {
    final startedAtByOperation = <String, DateTime>{};
    final durations = <Duration>[];

    for (final entry in logs) {
      final operationId = entry.operationId;
      if (operationId == null) {
        continue;
      }

      if (entry.eventType == SyncLogEventType.processingStarted) {
        startedAtByOperation[operationId] = entry.timestamp;
      } else if (entry.eventType == SyncLogEventType.processingFinished) {
        final startedAt = startedAtByOperation.remove(operationId);
        if (startedAt != null && !entry.timestamp.isBefore(startedAt)) {
          durations.add(entry.timestamp.difference(startedAt));
        }
      }
    }

    if (durations.isEmpty) {
      return Duration.zero;
    }

    final totalMicroseconds = durations.fold<int>(
      0,
      (total, duration) => total + duration.inMicroseconds,
    );
    return Duration(microseconds: totalMicroseconds ~/ durations.length);
  }
}
