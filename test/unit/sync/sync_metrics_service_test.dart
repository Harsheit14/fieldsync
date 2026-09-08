import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:fieldsync/features/sync/data/mappers/pending_operation_mapper.dart';
import 'package:fieldsync/features/sync/data/services/sync_metrics_service_impl.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake/in_memory_database.dart';
import '../../helpers/fixtures/sync_fixtures.dart';

void main() {
  test(
    'calculates status, rate, retry, and duration metrics from observations',
    () async {
      final database = createInMemoryDatabase();
      addTearDown(database.close);
      final logger = SyncLoggerImpl();
      final dao = PendingOperationsDao(database);
      const mapper = PendingOperationMapper();
      final entries = [
        SyncFixtures.operation(status: PendingOperationStatus.pending),
        SyncFixtures.operation(
          id: 'completed',
          status: PendingOperationStatus.completed,
        ),
        SyncFixtures.operation(
          id: 'failed',
          status: PendingOperationStatus.failed,
        ),
        SyncFixtures.operation(
          id: 'retry',
          status: PendingOperationStatus.retryScheduled,
          retryCount: 2,
        ),
      ];
      for (final entry in entries) {
        await dao.enqueue(mapper.toCompanion(entry));
      }
      await logger.log(SyncFixtures.log());
      await logger.log(
        SyncFixtures.log(
          eventType: SyncLogEventType.processingFinished,
          timestamp: SyncFixtures.timestamp.add(const Duration(seconds: 2)),
        ),
      );

      final metrics = await SyncMetricsServiceImpl(
        database,
        logger,
      ).calculate();

      expect(metrics.queueSize, 2);
      expect(metrics.completedCount, 1);
      expect(metrics.failedCount, 1);
      expect(metrics.successRate, 0.5);
      expect(metrics.failureRate, 0.5);
      expect(metrics.averageRetryCount, 0.5);
      expect(metrics.averageSyncDuration, const Duration(seconds: 2));
    },
  );
}
