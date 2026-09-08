import 'dart:async';

import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:fieldsync/features/sync/data/services/sync_coordinator_impl.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures/sync_fixtures.dart';
import '../../helpers/mocks/sync_mocks.dart';

void main() {
  late MockConnectivityService connectivity;
  late MockPendingOperationsRepository repository;
  late MockSynchronizationService synchronizationService;
  late SyncLoggerImpl logger;

  setUp(() {
    connectivity = MockConnectivityService();
    repository = MockPendingOperationsRepository();
    synchronizationService = MockSynchronizationService();
    logger = SyncLoggerImpl();

    when(() => connectivity.isConnected()).thenAnswer((_) async => true);

    when(
      () => connectivity.watchConnectivity(),
    ).thenAnswer((_) => Stream<bool>.value(true));

    when(() => repository.resetProcessingOperations()).thenAnswer((_) async {});

    when(
      () => repository.getNextScheduledOperation(),
    ).thenAnswer((_) async => null);

    when(
      () => synchronizationService.synchronizeOnce(),
    ).thenAnswer((_) async {});
  });

  SyncCoordinatorImpl createCoordinator() {
    return SyncCoordinatorImpl(
      connectivity,
      repository,
      synchronizationService,
      logger,
    );
  }

  test('resets processing operations when the coordinator starts', () async {
    when(
      () => repository.watchReadyOperations(),
    ).thenAnswer((_) => Stream.value(const <PendingOperationEntity>[]));

    final coordinator = createCoordinator();

    await coordinator.start();

    verify(() => repository.resetProcessingOperations()).called(1);

    await coordinator.stop();
  });

  test('starts synchronization when connectivity is available', () async {
    when(
      () => repository.watchReadyOperations(),
    ).thenAnswer((_) => Stream.value([SyncFixtures.operation()]));

    final coordinator = createCoordinator();

    await coordinator.start();

    await untilCalled(() => synchronizationService.synchronizeOnce());

    verify(() => synchronizationService.synchronizeOnce()).called(1);

    await coordinator.stop();
  });

  test(
    'does not start a second synchronization while one is already running',
    () async {
      final synchronizationCompleter = Completer<void>();

      when(
        () => repository.watchReadyOperations(),
      ).thenAnswer((_) => Stream.value([SyncFixtures.operation()]));

      when(
        () => synchronizationService.synchronizeOnce(),
      ).thenAnswer((_) => synchronizationCompleter.future);

      final coordinator = createCoordinator();

      await coordinator.start();

      await untilCalled(() => synchronizationService.synchronizeOnce());

      // Trigger another synchronization while the first one
      // is still running.
      await coordinator.syncNow();

      verify(() => synchronizationService.synchronizeOnce()).called(1);

      synchronizationCompleter.complete();

      await coordinator.stop();
    },
  );

  test('stops processing synchronization when connectivity drops', () async {
    final connectivityController = StreamController<bool>();
    final synchronizationCompleter = Completer<void>();

    addTearDown(connectivityController.close);

    when(
      () => connectivity.watchConnectivity(),
    ).thenAnswer((_) => connectivityController.stream);

    when(
      () => repository.watchReadyOperations(),
    ).thenAnswer((_) => Stream.value([SyncFixtures.operation()]));

    when(
      () => synchronizationService.synchronizeOnce(),
    ).thenAnswer((_) => synchronizationCompleter.future);

    final coordinator = createCoordinator();

    await coordinator.start();

    // The coordinator skips the first connectivity event.
    connectivityController.add(true);

    await untilCalled(() => synchronizationService.synchronizeOnce());

    // Simulate online -> offline.
    connectivityController.add(false);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Complete the synchronization that was already running.
    synchronizationCompleter.complete();

    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Attempting another synchronization while offline must
    // not invoke the synchronization service again.
    await coordinator.syncNow();

    verify(() => synchronizationService.synchronizeOnce()).called(1);

    await coordinator.stop();
  });

  test('does not synchronize while connectivity is offline', () async {
    final operation = SyncFixtures.operation();

    when(() => connectivity.isConnected()).thenAnswer((_) async => false);

    when(
      () => connectivity.watchConnectivity(),
    ).thenAnswer((_) => Stream<bool>.value(false));

    when(
      () => repository.watchReadyOperations(),
    ).thenAnswer((_) => Stream.value([operation]));

    final coordinator = createCoordinator();

    await coordinator.start();

    await Future<void>.delayed(const Duration(milliseconds: 100));

    verifyNever(() => synchronizationService.synchronizeOnce());

    await coordinator.stop();
  });

  test(
    'starts synchronization after reconnecting from offline state',
    () async {
      final connectivityController = StreamController<bool>();

      addTearDown(connectivityController.close);

      when(() => connectivity.isConnected()).thenAnswer((_) async => false);

      when(
        () => connectivity.watchConnectivity(),
      ).thenAnswer((_) => connectivityController.stream);

      when(
        () => repository.watchReadyOperations(),
      ).thenAnswer((_) => Stream.value([SyncFixtures.operation()]));

      final coordinator = createCoordinator();

      await coordinator.start();

      verifyNever(() => synchronizationService.synchronizeOnce());

      // First event is skipped by the coordinator.
      connectivityController.add(false);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Reconnect.
      connectivityController.add(true);

      await untilCalled(() => synchronizationService.synchronizeOnce());

      verify(() => synchronizationService.synchronizeOnce()).called(1);

      await coordinator.stop();
    },
  );

  test('stops cleanly and does not start synchronization again', () async {
    when(
      () => repository.watchReadyOperations(),
    ).thenAnswer((_) => Stream.value([SyncFixtures.operation()]));

    final coordinator = createCoordinator();

    await coordinator.start();

    await untilCalled(() => synchronizationService.synchronizeOnce());

    await coordinator.stop();

    await coordinator.syncNow();

    verify(() => synchronizationService.synchronizeOnce()).called(1);
  });
}
