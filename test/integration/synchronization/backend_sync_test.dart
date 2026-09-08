import 'package:dio/dio.dart';
import 'package:fieldsync/features/sync/data/handlers/survey_sync_handler.dart';
import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:fieldsync/features/sync/data/mappers/pending_operation_mapper.dart';
import 'package:fieldsync/features/sync/data/policies/exponential_backoff_retry_policy.dart';
import 'package:fieldsync/features/sync/data/repositories/pending_operations_repository_impl.dart';
import 'package:fieldsync/features/sync/data/services/remote_sync_service.dart';
import 'package:fieldsync/features/sync/data/services/synchronization_service_impl.dart';
import 'package:fieldsync/features/sync/data/services/sync_coordinator_impl.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake/in_memory_database.dart';
import '../../helpers/fixtures/sync_fixtures.dart';
import '../../helpers/mocks/sync_mocks.dart';

void main() {
  test('syncs a survey from local outbox to the real backend', () async {
    final database = createInMemoryDatabase();
    addTearDown(database.close);

    final logger = SyncLoggerImpl();
    final connectivity = MockConnectivityService();

    when(() => connectivity.isConnected()).thenAnswer((_) async => true);

    when(
      () => connectivity.watchConnectivity(),
    ).thenAnswer((_) => const Stream<bool>.empty());

    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );

    final remote = RemoteSyncServiceImpl(dio: dio);

    final repository = PendingOperationsRepositoryImpl(
      PendingOperationsDao(database),
      const PendingOperationMapper(),
      logger,
    );

    final handler = SurveySyncHandler(remote, logger);

    final synchronizationService = SynchronizationServiceImpl(
      repository,
      [handler],
      const ExponentialBackoffRetryPolicy(),
      logger,
    );

    final coordinator = SyncCoordinatorImpl(
      connectivity,
      repository,
      synchronizationService,
      logger,
    );

    await coordinator.start();

    addTearDown(coordinator.stop);

    final survey = SyncFixtures.survey(
      id: '550e8400-e29b-41d4-a716-446655440000',
    );

    final operation = PendingOperationEntity(
      id: '650e8400-e29b-41d4-a716-446655440000',
      entityType: 'Survey',
      entityId: survey.id,
      operationType: PendingOperationType.create,
      payload:
          '''
{
  "id": "${survey.id}",
  "farmerName": "${survey.farmerName}",
  "cropType": "${survey.cropType}",
  "fieldArea": ${survey.fieldArea},
  "latitude": ${survey.latitude},
  "longitude": ${survey.longitude},
  "photoPaths": [],
  "status": "${survey.status}",
  "createdAt": "${survey.createdAt.toIso8601String()}",
  "updatedAt": "${survey.updatedAt.toIso8601String()}"
}
''',
      createdAt: DateTime.now(),
      retryCount: 0,
      status: PendingOperationStatus.pending,
    );

    await repository.enqueueOperation(operation);

    final completed = await PendingOperationsDao(database)
        .watchAllOperations()
        .firstWhere(
          (items) =>
              items.isNotEmpty &&
              items.single.status == PendingOperationStatus.completed.name,
        );

    expect(completed.single.id, operation.id);
    expect(completed.single.status, PendingOperationStatus.completed.name);
  });
}
