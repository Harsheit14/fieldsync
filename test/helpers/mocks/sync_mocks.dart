import 'package:fieldsync/features/survey/domain/repositories/survey_repository.dart';
import 'package:fieldsync/features/sync/data/services/remote_sync_service.dart';
import 'package:fieldsync/features/sync/domain/handlers/sync_handler.dart';
import 'package:fieldsync/features/sync/domain/repositories/pending_operations_repository.dart';
import 'package:fieldsync/features/sync/domain/services/connectivity_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSurveyRepository extends Mock implements SurveyRepository {}

class MockPendingOperationsRepository extends Mock
    implements PendingOperationsRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockRemoteSyncService extends Mock implements RemoteSyncService {}

class MockSyncHandler extends Mock implements SyncHandler {}
