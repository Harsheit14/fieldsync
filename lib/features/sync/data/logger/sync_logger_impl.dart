import 'dart:async';

import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';

/// A lightweight in-memory store. It can be replaced by a database-backed
/// implementation without changing synchronization callers.
class SyncLoggerImpl implements SyncLogger {
  final List<SyncLogEntry> _entries = [];
  final StreamController<List<SyncLogEntry>> _controller =
      StreamController<List<SyncLogEntry>>.broadcast();

  @override
  Future<void> log(SyncLogEntry entry) async {
    _entries.add(entry);
    _emit();
  }

  @override
  Stream<List<SyncLogEntry>> watchLogs() async* {
    yield List.unmodifiable(_entries);
    yield* _controller.stream;
  }

  @override
  Future<void> clearLogs() async {
    _entries.clear();
    _emit();
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_entries));
    }
  }
}
