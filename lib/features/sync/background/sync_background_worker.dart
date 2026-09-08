import 'package:dio/dio.dart';
import 'package:fieldsync/core/config/app_config.dart';
import 'package:fieldsync/core/database/app_database.dart';
import 'package:fieldsync/features/sync/background/background_sync_runner.dart';
import 'package:fieldsync/features/sync/data/handlers/survey_sync_handler.dart';
import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:fieldsync/features/sync/data/mappers/pending_operation_mapper.dart';
import 'package:fieldsync/features/sync/data/policies/exponential_backoff_retry_policy.dart';
import 'package:fieldsync/features/sync/data/repositories/pending_operations_repository_impl.dart';
import 'package:fieldsync/features/sync/data/services/remote_sync_service.dart';
import 'package:fieldsync/features/sync/data/services/synchronization_service_impl.dart';
import 'package:fieldsync/features/sync/domain/services/synchronization_service.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void syncBackgroundCallback() {
  Workmanager().executeTask((task, inputData) async {
    AppDatabase? database;

    try {
      await AppConfig.initialize();

      database = AppDatabase();

      final syncLogger = SyncLoggerImpl();

      final pendingOperationsRepository = PendingOperationsRepositoryImpl(
        PendingOperationsDao(database),
        const PendingOperationMapper(),
        syncLogger,
      );

      final remoteSyncService = RemoteSyncServiceImpl(
        dio: Dio(
          BaseOptions(
            baseUrl: AppConfig.instance.apiBaseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 10),
            sendTimeout: const Duration(seconds: 10),
            headers: {'Content-Type': 'application/json'},
          ),
        ),
      );

      final surveySyncHandler = SurveySyncHandler(
        remoteSyncService,
        syncLogger,
      );

      final SynchronizationService synchronizationService =
          SynchronizationServiceImpl(
            pendingOperationsRepository,
            [surveySyncHandler],
            const ExponentialBackoffRetryPolicy(),
            syncLogger,
          );

      final runner = BackgroundSyncRunner(synchronizationService);

      await runner.run();

      return true;
    } catch (_) {
      return false;
    } finally {
      await database?.close();
    }
  });
}

void registerSyncBackgroundTask() {
  Workmanager().registerPeriodicTask(
    'fieldsync-background-sync',
    'fieldsync-sync',
    frequency: const Duration(hours: 1),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}
