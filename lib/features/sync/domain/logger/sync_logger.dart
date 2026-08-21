import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';

/// Records synchronization events without coupling sync code to a log store.
abstract class SyncLogger {
  Future<void> log(SyncLogEntry entry);

  Stream<List<SyncLogEntry>> watchLogs();

  Future<void> clearLogs();
}
