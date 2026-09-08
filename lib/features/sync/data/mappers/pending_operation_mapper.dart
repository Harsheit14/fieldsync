import 'package:drift/drift.dart';
import 'package:fieldsync/core/database/app_database.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';

class PendingOperationMapper {
  const PendingOperationMapper();

  PendingOperationsCompanion toCompanion(PendingOperationEntity entity) {
    return PendingOperationsCompanion(
      id: Value(entity.id),
      entityType: Value(entity.entityType),
      entityId: Value(entity.entityId),
      operationType: Value(entity.operationType.name),
      payload: Value(entity.payload),
      createdAt: Value(entity.createdAt),
      retryCount: Value(entity.retryCount),
      status: Value(entity.status.name),
      nextRetryAt: Value(entity.nextRetryAt),
      lastAttemptAt: Value(entity.lastAttemptAt),
      errorMessage: Value(entity.errorMessage),
    );
  }

  PendingOperationEntity toEntity(PendingOperation operation) {
    return PendingOperationEntity(
      id: operation.id,
      entityType: operation.entityType,
      entityId: operation.entityId,
      operationType: PendingOperationType.values.byName(
        operation.operationType,
      ),
      payload: operation.payload,
      createdAt: operation.createdAt,
      retryCount: operation.retryCount,
      status: PendingOperationStatus.values.byName(operation.status),
      nextRetryAt: operation.nextRetryAt,
      lastAttemptAt: operation.lastAttemptAt,
      errorMessage: operation.errorMessage,
    );
  }
}
