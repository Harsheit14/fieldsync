import 'package:fieldsync/features/sync/data/services/synchronization_service_impl.dart';
import 'package:fieldsync/features/sync/data/policies/exponential_backoff_retry_policy.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';
import 'package:fieldsync/features/sync/domain/services/synchronization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';

import '../../helpers/fixtures/sync_fixtures.dart';
import '../../helpers/mocks/sync_mocks.dart';

class MockSyncLogger extends Mock implements SyncLogger {}

void main() {
  late MockPendingOperationsRepository repository;
  late MockSyncHandler handler;
  late MockSyncLogger logger;
  late SynchronizationService service;
  setUpAll(() {
    registerFallbackValue(SyncFixtures.log());
    registerFallbackValue(SyncFixtures.operation());
  });

  setUp(() {
    repository = MockPendingOperationsRepository();
    handler = MockSyncHandler();
    logger = MockSyncLogger();

    when(() => logger.log(any())).thenAnswer((_) async {});

    service = SynchronizationServiceImpl(
      repository,
      [handler],
      ExponentialBackoffRetryPolicy(),
      logger,
    );
  });

  group('synchronizeOnce', () {
    test('processes successful operation and marks it completed', () async {
      final operation = SyncFixtures.operation();

      when(
        () => repository.watchReadyOperations(),
      ).thenAnswer((_) => Stream.value([operation]));

      when(() => handler.supports('Survey')).thenReturn(true);

      when(
        () => handler.process(operation),
      ).thenAnswer((_) async => SyncFixtures.successResult);

      when(
        () => repository.markProcessing(operation.id),
      ).thenAnswer((_) async {});

      when(
        () => repository.markCompleted(operation.id),
      ).thenAnswer((_) async {});

      await service.synchronizeOnce();

      verify(() => handler.process(operation)).called(1);

      verify(() => repository.markProcessing(operation.id)).called(1);

      verify(() => repository.markCompleted(operation.id)).called(1);
    });

    test('schedules retry for retryable failure', () async {
      final operation = SyncFixtures.operation();

      when(
        () => repository.watchReadyOperations(),
      ).thenAnswer((_) => Stream.value([operation]));

      when(() => handler.supports('Survey')).thenReturn(true);

      when(
        () => handler.process(operation),
      ).thenAnswer((_) async => SyncFixtures.retryResult);

      when(
        () => repository.markProcessing(operation.id),
      ).thenAnswer((_) async {});

      when(
        () => repository.markRetryScheduled(
          operation.id,
          1,
          any(),
          errorMessage: 'Try again',
        ),
      ).thenAnswer((_) async {});

      await service.synchronizeOnce();

      verify(
        () => repository.markRetryScheduled(
          operation.id,
          1,
          any(),
          errorMessage: 'Try again',
        ),
      ).called(1);
    });

    test('marks permanent failure without scheduling retry', () async {
      final operation = SyncFixtures.operation();

      when(
        () => repository.watchReadyOperations(),
      ).thenAnswer((_) => Stream.value([operation]));

      when(() => handler.supports('Survey')).thenReturn(true);

      when(() => handler.process(operation)).thenAnswer(
        (_) async => SyncResult.failure(message: 'Invalid survey payload.'),
      );

      when(
        () => repository.markProcessing(operation.id),
      ).thenAnswer((_) async {});

      when(
        () => repository.markFailed(operation.id, 'Invalid survey payload.'),
      ).thenAnswer((_) async {});

      await service.synchronizeOnce();

      verify(
        () => repository.markFailed(operation.id, 'Invalid survey payload.'),
      ).called(1);

      verifyNever(
        () => repository.markRetryScheduled(
          any(),
          any(),
          any(),
          errorMessage: any(named: 'errorMessage'),
        ),
      );
    });

    test(
      'marks operation failed when no handler supports entity type',
      () async {
        final operation = SyncFixtures.operation();

        when(
          () => repository.watchReadyOperations(),
        ).thenAnswer((_) => Stream.value([operation]));

        when(() => handler.supports('Survey')).thenReturn(false);

        when(
          () => repository.markFailed(
            operation.id,
            'No sync handler registered for Survey.',
          ),
        ).thenAnswer((_) async {});

        await service.synchronizeOnce();

        verify(
          () => repository.markFailed(
            operation.id,
            'No sync handler registered for Survey.',
          ),
        ).called(1);

        verifyNever(() => handler.process(any()));
      },
    );

    test('processes multiple operations in repository order', () async {
      final first = SyncFixtures.operation(id: 'operation-1');
      final second = SyncFixtures.operation(id: 'operation-2');

      when(
        () => repository.watchReadyOperations(),
      ).thenAnswer((_) => Stream.value([first, second]));

      when(() => handler.supports('Survey')).thenReturn(true);

      when(
        () => handler.process(any()),
      ).thenAnswer((_) async => SyncFixtures.successResult);

      when(() => repository.markProcessing(any())).thenAnswer((_) async {});

      when(() => repository.markCompleted(any())).thenAnswer((_) async {});

      await service.synchronizeOnce();

      verifyInOrder([
        () => handler.process(first),
        () => handler.process(second),
      ]);
    });
  });
}
