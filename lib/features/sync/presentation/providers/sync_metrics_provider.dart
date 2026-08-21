import 'package:fieldsync/core/providers/database_provider.dart';
import 'package:fieldsync/features/sync/data/services/sync_metrics_service_impl.dart';
import 'package:fieldsync/features/sync/domain/metrics/sync_metrics.dart';
import 'package:fieldsync/features/sync/domain/services/sync_metrics_service.dart';
import 'package:fieldsync/features/sync/presentation/providers/sync_logger_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncMetricsServiceProvider = Provider<SyncMetricsService>((ref) {
  return SyncMetricsServiceImpl(
    ref.watch(databaseProvider),
    ref.watch(syncLoggerProvider),
  );
});

final syncMetricsProvider = StreamProvider<SyncMetrics>((ref) {
  return ref.watch(syncMetricsServiceProvider).watchMetrics();
});
