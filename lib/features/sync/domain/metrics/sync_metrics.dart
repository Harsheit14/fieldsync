/// A point-in-time view of synchronization engine health.
class SyncMetrics {
  const SyncMetrics({
    required this.queueSize,
    required this.pendingCount,
    required this.processingCount,
    required this.completedCount,
    required this.failedCount,
    required this.retryScheduledCount,
    required this.successRate,
    required this.failureRate,
    required this.averageSyncDuration,
    required this.averageRetryCount,
  });

  final int queueSize;
  final int pendingCount;
  final int processingCount;
  final int completedCount;
  final int failedCount;
  final int retryScheduledCount;
  final double successRate;
  final double failureRate;
  final Duration averageSyncDuration;
  final double averageRetryCount;
}
