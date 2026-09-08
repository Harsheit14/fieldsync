import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:fieldsync/features/sync/data/mappers/pending_operation_mapper.dart';
import 'package:fieldsync/features/sync/data/repositories/pending_operations_repository_impl.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake/in_memory_database.dart';
import '../../helpers/fixtures/sync_fixtures.dart';

void main() {
  test(
    'preserves queue order and recovers processing operations after restart',
    () async {
      final database = createInMemoryDatabase();
      addTearDown(database.close);

      final repository = PendingOperationsRepositoryImpl(
        PendingOperationsDao(database),
        const PendingOperationMapper(),
        SyncLoggerImpl(),
      );

      final first = SyncFixtures.operation(
        id: 'first',
      );

      final second = SyncFixtures.operation(
        id: 'second',
        createdAt: SyncFixtures.timestamp.add(
          const Duration(seconds: 1),
        ),
      );

      await repository.enqueueOperation(first);
      await repository.enqueueOperation(second);

      final readyOperations =
          await repository.watchReadyOperations().first;

      expect(
        readyOperations.map((operation) => operation.id),
        ['first', 'second'],
      );

      await repository.markProcessing(first.id);
      await repository.resetProcessingOperations();

      final recovered =
          await repository.watchReadyOperations().first;

      expect(
        recovered.first.status,
        PendingOperationStatus.pending,
      );

      expect(
        recovered.map((operation) => operation.id),
        ['first', 'second'],
      );
    },
  );

  test(
    'marks an operation as retry scheduled',
    () async {
      final database = createInMemoryDatabase();
      addTearDown(database.close);

      final repository = PendingOperationsRepositoryImpl(
        PendingOperationsDao(database),
        const PendingOperationMapper(),
        SyncLoggerImpl(),
      );

      final operation = SyncFixtures.operation();

      await repository.enqueueOperation(operation);

      final nextRetryAt = DateTime.now().add(
        const Duration(seconds: 10),
      );

      await repository.markRetryScheduled(
        operation.id,
        1,
        nextRetryAt,
        errorMessage: 'Temporary network failure',
      );

      final scheduled =
          await repository.getNextScheduledOperation();

      expect(scheduled, isNotNull);
      expect(scheduled!.id, operation.id);
      expect(
        scheduled.status,
        PendingOperationStatus.retryScheduled,
      );
      expect(scheduled.retryCount, 1);
      expect(
        scheduled.errorMessage,
        'Temporary network failure',
      );
    },
  );

  test(
    'marks an operation as completed',
    () async {
      final database = createInMemoryDatabase();
      addTearDown(database.close);

      final repository = PendingOperationsRepositoryImpl(
        PendingOperationsDao(database),
        const PendingOperationMapper(),
        SyncLoggerImpl(),
      );

      final operation = SyncFixtures.operation();

      await repository.enqueueOperation(operation);
      await repository.markCompleted(operation.id);

      final readyOperations =
          await repository.watchReadyOperations().first;

      expect(
        readyOperations.any(
          (item) => item.id == operation.id,
        ),
        isFalse,
      );
    },
  );

  test(
    'marks an operation as permanently failed',
    () async {
      final database = createInMemoryDatabase();
      addTearDown(database.close);

      final repository = PendingOperationsRepositoryImpl(
        PendingOperationsDao(database),
        const PendingOperationMapper(),
        SyncLoggerImpl(),
      );

      final operation = SyncFixtures.operation();

      await repository.enqueueOperation(operation);

      await repository.markFailed(
        operation.id,
        'Invalid payload',
      );

      final readyOperations =
          await repository.watchReadyOperations().first;

      expect(
        readyOperations.any(
          (item) => item.id == operation.id,
        ),
        isFalse,
      );
    },
  );
}