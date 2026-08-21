import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';

final class SyncFixtures {
  static final timestamp = DateTime.utc(2025, 1, 1, 12);

  static SurveyEntity survey({String id = 'survey-1'}) => SurveyEntity(
    id: id,
    farmerName: 'Ada Farmer',
    cropType: 'Wheat',
    fieldArea: 12.5,
    latitude: 12.34,
    longitude: 56.78,
    photoPaths: const [],
    status: 'active',
    createdAt: timestamp,
    updatedAt: timestamp,
  );

  static PendingOperationEntity operation({
    String id = 'operation-1',
    PendingOperationStatus status = PendingOperationStatus.pending,
    int retryCount = 0,
    DateTime? createdAt,
  }) => PendingOperationEntity(
    id: id,
    entityType: 'Survey',
    entityId: 'survey-1',
    operationType: PendingOperationType.create,
    payload: '{}',
    createdAt: createdAt ?? timestamp,
    retryCount: retryCount,
    status: status,
  );

  static const successResult = SyncResult.success(message: 'Uploaded');
  static const retryResult = SyncResult.retry(message: 'Try again');

  static SyncLogEntry log({
    SyncLogEventType eventType = SyncLogEventType.processingStarted,
    DateTime? timestamp,
    String operationId = 'operation-1',
  }) => SyncLogEntry(
    timestamp: timestamp ?? SyncFixtures.timestamp,
    operationId: operationId,
    entityType: 'Survey',
    entityId: 'survey-1',
    eventType: eventType,
    message: eventType.name,
  );
}
