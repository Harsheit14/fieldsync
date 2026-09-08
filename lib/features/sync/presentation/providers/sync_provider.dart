import 'package:dio/dio.dart';
import 'package:fieldsync/core/config/app_config.dart';
import 'package:fieldsync/core/providers/database_provider.dart';
import 'package:fieldsync/features/sync/data/handlers/survey_sync_handler.dart';
import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/mappers/pending_operation_mapper.dart';
import 'package:fieldsync/features/sync/data/policies/exponential_backoff_retry_policy.dart';
import 'package:fieldsync/features/sync/data/repositories/pending_operations_repository_impl.dart';
import 'package:fieldsync/features/sync/data/services/remote_sync_service.dart';
import 'package:fieldsync/features/sync/data/services/sync_coordinator_impl.dart';
import 'package:fieldsync/features/sync/data/services/synchronization_service_impl.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/handlers/sync_handler.dart';
import 'package:fieldsync/features/sync/domain/policies/retry_policy.dart';
import 'package:fieldsync/features/sync/domain/repositories/pending_operations_repository.dart';
import 'package:fieldsync/features/sync/domain/services/synchronization_service.dart';
import 'package:fieldsync/features/sync/domain/services/sync_coordinator.dart';
import 'package:fieldsync/features/sync/presentation/providers/connectivity_provider.dart';
import 'package:fieldsync/features/sync/presentation/providers/sync_logger_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingOperationsRepositoryProvider =
    Provider<PendingOperationsRepository>((ref) {
      return PendingOperationsRepositoryImpl(
        PendingOperationsDao(ref.watch(databaseProvider)),
        const PendingOperationMapper(),
        ref.watch(syncLoggerProvider),
      );
    });

final pendingOperationsProvider = StreamProvider<List<PendingOperationEntity>>((
  ref,
) {
  final dao = PendingOperationsDao(ref.watch(databaseProvider));
  const mapper = PendingOperationMapper();

  return dao.watchAllOperations().map(
    (operations) => operations.map(mapper.toEntity).toList(),
  );
});

final remoteSyncServiceProvider = Provider<RemoteSyncService>((ref) {
  final config = AppConfig.instance;

  return RemoteSyncServiceImpl(
    dio: Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    ),
  );
});

final retryPolicyProvider = Provider<RetryPolicy>((ref) {
  return const ExponentialBackoffRetryPolicy();
});

final surveySyncHandlerProvider = Provider<SyncHandler>((ref) {
  return SurveySyncHandler(
    ref.watch(remoteSyncServiceProvider),
    ref.watch(syncLoggerProvider),
  );
});

final syncHandlersProvider = Provider<List<SyncHandler>>((ref) {
  return [ref.watch(surveySyncHandlerProvider)];
});

final synchronizationServiceProvider = Provider<SynchronizationService>((ref) {
  return SynchronizationServiceImpl(
    ref.watch(pendingOperationsRepositoryProvider),
    ref.watch(syncHandlersProvider),
    ref.watch(retryPolicyProvider),
    ref.watch(syncLoggerProvider),
  );
});

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinatorImpl(
    ref.watch(connectivityServiceProvider),
    ref.watch(pendingOperationsRepositoryProvider),
    ref.watch(synchronizationServiceProvider),
    ref.watch(syncLoggerProvider),
  );

  ref.onDispose(coordinator.stop);

  coordinator.start();

  return coordinator;
});

final syncStatusProvider = StreamProvider<bool>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider) as SyncCoordinatorImpl;

  return Stream<bool>.multi((controller) {
    controller.add(coordinator.isRunning);

    final subscription = coordinator.statusChanges.listen(controller.add);

    controller.onCancel = subscription.cancel;
  }).distinct();
});
