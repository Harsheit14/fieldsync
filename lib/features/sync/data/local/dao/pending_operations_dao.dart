import 'package:drift/drift.dart';
import 'package:fieldsync/core/database/app_database.dart';
import 'package:fieldsync/features/sync/data/local/tables/pending_operations.dart';
import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';

part 'pending_operations_dao.g.dart';

@DriftAccessor(tables: [PendingOperations])
class PendingOperationsDao extends DatabaseAccessor<AppDatabase>
    with _$PendingOperationsDaoMixin {
  PendingOperationsDao(super.db);

  Future<int> enqueue(PendingOperationsCompanion operation) {
    return into(pendingOperations).insert(operation);
  }

  Stream<List<PendingOperation>> watchReadyOperations() {
    final now = DateTime.now();
    return (select(pendingOperations)
          ..where(
            (operation) =>
                operation.status.equals(PendingOperationStatus.pending.name) |
                (operation.status.equals(
                      PendingOperationStatus.retryScheduled.name,
                    ) &
                    operation.nextRetryAt.isNotNull() &
                    operation.nextRetryAt.isSmallerOrEqualValue(now)),
          )
          ..orderBy([(operation) => OrderingTerm.asc(operation.createdAt)]))
        .watch();
  }

  Stream<List<PendingOperation>> watchAllOperations() {
    return (select(pendingOperations)
          ..orderBy([(operation) => OrderingTerm.desc(operation.createdAt)]))
        .watch();
  }

  Future<PendingOperation?> getNextScheduledOperation() {
    return (select(pendingOperations)
          ..where(
            (operation) => operation.status.equals(
              PendingOperationStatus.retryScheduled.name,
            ),
          )
          ..orderBy([
            (operation) => OrderingTerm.asc(operation.nextRetryAt),
            (operation) => OrderingTerm.asc(operation.createdAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> resetProcessingOperations() {
    return (update(pendingOperations)..where(
          (operation) =>
              operation.status.equals(PendingOperationStatus.processing.name),
        ))
        .write(
          PendingOperationsCompanion(
            status: Value(PendingOperationStatus.pending.name),
            nextRetryAt: const Value<DateTime?>(null),
            lastAttemptAt: const Value<DateTime?>(null),
            errorMessage: const Value<String?>(null),
          ),
        );
  }

  Future<int> markRetryScheduled(
    String id,
    int retryCount,
    DateTime nextRetryAt, {
    String? errorMessage,
  }) {
    return (update(
      pendingOperations,
    )..where((operation) => operation.id.equals(id))).write(
      PendingOperationsCompanion(
        status: Value(PendingOperationStatus.retryScheduled.name),
        retryCount: Value(retryCount),
        nextRetryAt: Value<DateTime?>(nextRetryAt),
        lastAttemptAt: Value<DateTime?>(DateTime.now()),
        errorMessage: errorMessage == null
            ? const Value.absent()
            : Value<String?>(errorMessage),
      ),
    );
  }

  Future<int> markProcessing(String id) {
    return (update(
      pendingOperations,
    )..where((operation) => operation.id.equals(id))).write(
      PendingOperationsCompanion(
        status: Value(PendingOperationStatus.processing.name),
        lastAttemptAt: Value<DateTime?>(DateTime.now()),
        nextRetryAt: const Value<DateTime?>(null),
        errorMessage: const Value<String?>(null),
      ),
    );
  }

  Future<int> markCompleted(String id) {
    return (update(
      pendingOperations,
    )..where((operation) => operation.id.equals(id))).write(
      PendingOperationsCompanion(
        status: Value(PendingOperationStatus.completed.name),
        nextRetryAt: const Value<DateTime?>(null),
        errorMessage: const Value<String?>(null),
      ),
    );
  }

  Future<int> markFailed(String id, String errorMessage) {
    return (update(
      pendingOperations,
    )..where((operation) => operation.id.equals(id))).write(
      PendingOperationsCompanion(
        status: Value(PendingOperationStatus.failed.name),
        lastAttemptAt: Value<DateTime?>(DateTime.now()),
        nextRetryAt: const Value<DateTime?>(null),
        errorMessage: Value<String?>(errorMessage),
      ),
    );
  }
}
