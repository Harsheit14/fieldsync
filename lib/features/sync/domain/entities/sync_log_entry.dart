/// The lifecycle events emitted by the synchronization subsystem.
enum SyncLogEventType {
  operationQueued,
  syncStarted,
  syncCompleted,
  syncFailed,
  retryScheduled,
  connectivityOnline,
  connectivityOffline,
  coordinatorStarted,
  coordinatorStopped,
  processingStarted,
  processingFinished,
  uploadSucceeded,
  uploadFailed,
}

/// An immutable, structured record of a synchronization event.
class SyncLogEntry {
  SyncLogEntry({
    required this.timestamp,
    required this.eventType,
    required this.message,
    this.operationId,
    this.entityType,
    this.entityId,
    Map<String, Object?>? metadata,
  }) : metadata = metadata == null ? null : Map.unmodifiable(metadata);

  final DateTime timestamp;
  final String? operationId;
  final String? entityType;
  final String? entityId;
  final SyncLogEventType eventType;
  final String message;
  final Map<String, Object?>? metadata;
}
