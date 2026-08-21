enum PendingOperationType { create, update, delete }

enum PendingOperationStatus {
  pending,
  processing,
  completed,
  failed,
  retryScheduled,
}

class PendingOperationEntity {
  const PendingOperationEntity({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operationType,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    required this.status,
    this.nextRetryAt,
    this.lastAttemptAt,
    this.errorMessage,
  });

  final String id;
  final String entityType;
  final String entityId;
  final PendingOperationType operationType;
  final String payload;
  final DateTime createdAt;
  final int retryCount;
  final PendingOperationStatus status;
  final DateTime? nextRetryAt;
  final DateTime? lastAttemptAt;
  final String? errorMessage;
}
