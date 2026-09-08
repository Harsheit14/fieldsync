import 'package:fieldsync/features/sync/domain/metrics/sync_metrics.dart';

/// Provides read-only health metrics for the synchronization engine.
abstract class SyncMetricsService {
  Future<SyncMetrics> calculate();

  Stream<SyncMetrics> watchMetrics();
}
