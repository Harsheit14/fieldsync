import 'dart:async';

import 'package:fieldsync/features/survey/data/local/dao/survey_dao.dart';
import 'package:fieldsync/features/survey/data/mappers/survey_mapper.dart';
import 'package:fieldsync/features/survey/data/repositories/survey_repository_impl.dart';
import 'package:fieldsync/features/sync/data/handlers/survey_sync_handler.dart';
import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:fieldsync/features/sync/data/mappers/pending_operation_mapper.dart';
import 'package:fieldsync/features/sync/data/policies/exponential_backoff_retry_policy.dart';
import 'package:fieldsync/features/sync/data/repositories/pending_operations_repository_impl.dart';
import 'package:fieldsync/features/sync/data/services/sync_coordinator_impl.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake/in_memory_database.dart';
import '../../helpers/fixtures/sync_fixtures.dart';
import '../../helpers/mocks/sync_mocks.dart';

void main() {
  test('queues offline work and completes it after reconnecting', () async {
    final database = createInMemoryDatabase();
    addTearDown(database.close);

    final logger = SyncLoggerImpl();
    final connectivity = MockConnectivityService();
    final remote = MockRemoteSyncService();

    final connectivityEvents = StreamController<bool>.broadcast();
    addTearDown(connectivityEvents.close);

    when(
      () => connectivity.isConnected(),
    ).thenAnswer((_) async => false);

    when(
      () => connectivity.watchConnectivity(),
    ).thenAnswer((_) => connectivityEvents.stream);

    when(
      () => remote.create(
        'Survey',
        any(),
        any(),
        any(),
      ),
    ).thenAnswer(
      (_) async => const SyncResult.success(),
    );

    final surveys = SurveyRepositoryImpl(
      SurveyDao(database),
      const SurveyMapper(),
      logger,
    );

    final operations = PendingOperationsRepositoryImpl(
      PendingOperationsDao(database),
      const PendingOperationMapper(),
      logger,
    );

    final coordinator = SyncCoordinatorImpl(
      connectivity,
      operations,
      [
        SurveySyncHandler(
          remote,
          logger,
        ),
      ],
      const ExponentialBackoffRetryPolicy(),
      logger,
    );

    await coordinator.start();

    await surveys.createSurvey(
      SyncFixtures.survey(),
    );

    expect(
      (await PendingOperationsDao(
        database,
      ).watchAllOperations().first).single.status,
      PendingOperationStatus.pending.name,
    );

    connectivityEvents
      ..add(false)
      ..add(true);

    final completed = PendingOperationsDao(
      database,
    ).watchAllOperations().firstWhere(
          (items) =>
              items.single.status ==
              PendingOperationStatus.completed.name,
        );

    expect(
      (await completed).single.status,
      PendingOperationStatus.completed.name,
    );

    verify(
      () => remote.create(
        'Survey',
        any(),
        any(),
        any(),
      ),
    ).called(1);

    await coordinator.stop();
  });
}