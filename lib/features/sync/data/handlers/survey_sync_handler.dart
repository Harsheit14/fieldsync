import 'dart:convert';

import 'package:fieldsync/features/sync/data/services/remote_sync_service.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';
import 'package:fieldsync/features/sync/domain/handlers/sync_handler.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';

class SurveySyncHandler implements SyncHandler {
  SurveySyncHandler(
    this._remoteSyncService,
    this._syncLogger,
  );

  final RemoteSyncService _remoteSyncService;
  final SyncLogger _syncLogger;

  static const _entityType = 'Survey';

  @override
  bool supports(String entityType) {
    return entityType == _entityType;
  }

  @override
  Future<SyncResult> process(
    PendingOperationEntity operation,
  ) async {
    try {
      final payload = _deserializePayload(operation.payload);

      final result = switch (operation.operationType) {
        PendingOperationType.create => _remoteSyncService.create(
            _entityType,
            operation.id,
            operation.entityId,
            payload,
          ),
        PendingOperationType.update => _remoteSyncService.update(
            _entityType,
            operation.id,
            operation.entityId,
            payload,
          ),
        PendingOperationType.delete => _remoteSyncService.delete(
            _entityType,
            operation.id,
            operation.entityId,
            payload,
          ),
      };

      final resolvedResult = await result;

      await _logResult(
        operation,
        resolvedResult,
      );

      return resolvedResult;
    } catch (error) {
      final result = SyncResult.retry(
        message: 'Survey upload failed.',
        error: error,
      );

      await _logResult(
        operation,
        result,
      );

      return result;
    }
  }

  Future<void> _logResult(
    PendingOperationEntity operation,
    SyncResult result,
  ) {
    return _syncLogger.log(
      SyncLogEntry(
        timestamp: DateTime.now(),
        operationId: operation.id,
        entityType: operation.entityType,
        entityId: operation.entityId,
        eventType: result.success
            ? SyncLogEventType.uploadSucceeded
            : SyncLogEventType.uploadFailed,
        message: result.success
            ? 'Survey upload succeeded.'
            : result.message ?? 'Survey upload failed.',
        metadata: {
          'operationType': operation.operationType.name,
        },
      ),
    );
  }

  Map<String, dynamic> _deserializePayload(
    String payload,
  ) {
    final decoded = jsonDecode(payload);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return Map<String, dynamic>.from(decoded as Map);
  }
}