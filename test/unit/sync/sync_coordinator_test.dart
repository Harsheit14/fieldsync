import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:fieldsync/features/sync/data/policies/exponential_backoff_retry_policy.dart';
import 'package:fieldsync/features/sync/data/services/sync_coordinator_impl.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures/sync_fixtures.dart';
import '../../helpers/mocks/sync_mocks.dart';

void main() {
  late MockConnectivityService connectivity;
  late MockPendingOperationsRepository repository;
  late MockSyncHandler handler;
  late SyncLoggerImpl logger;

  setUp(() {
    connectivity = MockConnectivityService();
    repository = MockPendingOperationsRepository();
    handler = MockSyncHandler();
    logger = SyncLoggerImpl();

    when(() => connectivity.isConnected()).thenAnswer((_) async => true);

    when(
      () => connectivity.watchConnectivity(),
    ).thenAnswer((_) => Stream<bool>.value(true));

    when(() => repository.resetProcessingOperations()).thenAnswer((_) async {});

    when(
      () => repository.getNextScheduledOperation(),
    ).thenAnswer((_) async => null);

    when(() => repository.markProcessing(any())).thenAnswer((_) async {});

    when(() => handler.supports('Survey')).thenReturn(true);
  });

  SyncCoordinatorImpl createCoordinator() {
    return SyncCoordinatorImpl(
      connectivity,
      repository,
      [handler],
      const ExponentialBackoffRetryPolicy(),
      logger,
    );
  }

  test('processes a successful operation and records its lifecycle', () async {
    final operation = SyncFixtures.operation();

    when(
      () => repository.watchReadyOperations(),
    ).thenAnswer((_) => Stream.value([operation]));

    when(
      () => handler.process(operation),
    ).thenAnswer((_) async => SyncFixtures.successResult);

    when(() => repository.markCompleted(operation.id)).thenAnswer((_) async {});

    final coordinator = createCoordinator();

    await coordinator.start();

    await untilCalled(() => repository.markCompleted(operation.id));

    await coordinator.stop();

    verify(() => repository.markProcessing(operation.id)).called(1);

    verify(() => repository.markCompleted(operation.id)).called(1);

    final logs = await logger.watchLogs().first;

    expect(
      logs.map((entry) => entry.eventType),
      containsAll([
        SyncLogEventType.coordinatorStarted,
        SyncLogEventType.processingStarted,
        SyncLogEventType.syncCompleted,
      ]),
    );
  });

  test('schedules a retry for retryable handler failures', () async {
    final operation = SyncFixtures.operation();

    when(
      () => repository.watchReadyOperations(),
    ).thenAnswer((_) => Stream.value([operation]));

    when(
      () => handler.process(operation),
    ).thenAnswer((_) async => SyncFixtures.retryResult);

    when(
      () => repository.markRetryScheduled(
        operation.id,
        1,
        any(),
        errorMessage: any(named: 'errorMessage'),
      ),
    ).thenAnswer((_) async {});

    final coordinator = createCoordinator();

    await coordinator.start();

    await untilCalled(
      () => repository.markRetryScheduled(
        operation.id,
        1,
        any(),
        errorMessage: any(named: 'errorMessage'),
      ),
    );

    await coordinator.stop();

    verify(
      () => repository.markRetryScheduled(
        operation.id,
        1,
        any(),
        errorMessage: any(named: 'errorMessage'),
      ),
    ).called(1);

    expect(
      (await logger.watchLogs().first).map((entry) => entry.eventType),
      contains(SyncLogEventType.retryScheduled),
    );
  });

  test('resets retry count when retry budget is exhausted', () async {
    final operation = SyncFixtures.operation(retryCount: 5);

    when(
      () => repository.watchReadyOperations(),
    ).thenAnswer((_) => Stream.value([operation]));

    when(
      () => handler.process(operation),
    ).thenAnswer((_) async => SyncFixtures.retryResult);

    when(
      () => repository.markRetryScheduled(
        operation.id,
        0,
        any(),
        errorMessage: any(named: 'errorMessage'),
      ),
    ).thenAnswer((_) async {});

    final coordinator = createCoordinator();

    await coordinator.start();

    await untilCalled(
      () => repository.markRetryScheduled(
        operation.id,
        0,
        any(),
        errorMessage: any(named: 'errorMessage'),
      ),
    );

    await coordinator.stop();

    verify(
      () => repository.markRetryScheduled(
        operation.id,
        0,
        any(),
        errorMessage: any(named: 'errorMessage'),
      ),
    ).called(1);

    final logs = await logger.watchLogs().first;

    expect(
      logs.any(
        (entry) =>
            entry.eventType == SyncLogEventType.retryScheduled &&
            entry.metadata?['retryCycleReset'] == true,
      ),
      isTrue,
    );
  });

  test('permanently fails non-retryable operations', () async {
    final operation = SyncFixtures.operation();

    const failure = SyncResult.failure(message: 'Invalid survey payload.');

    when(
      () => repository.watchReadyOperations(),
    ).thenAnswer((_) => Stream.value([operation]));

    when(() => handler.process(operation)).thenAnswer((_) async => failure);

    when(
      () => repository.markFailed(operation.id, 'Invalid survey payload.'),
    ).thenAnswer((_) async {});

    final coordinator = createCoordinator();

    await coordinator.start();

    await untilCalled(
      () => repository.markFailed(operation.id, 'Invalid survey payload.'),
    );

    await coordinator.stop();

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
}
