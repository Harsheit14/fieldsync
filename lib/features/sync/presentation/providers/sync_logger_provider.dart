import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application-scoped logger shared by synchronization collaborators.
final syncLoggerProvider = Provider<SyncLogger>((ref) {
  return SyncLoggerImpl();
});

final syncLogsProvider = StreamProvider((ref) {
  return ref.watch(syncLoggerProvider).watchLogs();
});
