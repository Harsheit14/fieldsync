import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';

abstract class SyncHandler {
  bool supports(String entityType);

  Future<SyncResult> process(PendingOperationEntity operation);
}