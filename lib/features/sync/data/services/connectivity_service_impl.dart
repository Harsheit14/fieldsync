import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:fieldsync/features/sync/domain/logger/sync_logger.dart';
import 'package:fieldsync/features/sync/domain/services/connectivity_service.dart';

class ConnectivityServiceImpl implements ConnectivityService {
  ConnectivityServiceImpl(this._connectivity, this._syncLogger);

  final Connectivity _connectivity;
  final SyncLogger _syncLogger;

  @override
  Stream<bool> watchConnectivity() async* {
    var lastEmitted = await isConnected();
    await _logConnectivity(lastEmitted);
    yield lastEmitted;

    try {
      await for (final results in _connectivity.onConnectivityChanged) {
        final current = _hasConnection(results);
        if (current == lastEmitted) {
          continue;
        }

        lastEmitted = current;
        await _logConnectivity(current);
        yield current;
      }
    } catch (_) {
      if (lastEmitted) {
        await _logConnectivity(false);
        yield false;
      }
    }
  }

  @override
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasConnection(results);
    } catch (_) {
      return false;
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _logConnectivity(bool isConnected) {
    return _syncLogger.log(
      SyncLogEntry(
        timestamp: DateTime.now(),
        eventType: isConnected
            ? SyncLogEventType.connectivityOnline
            : SyncLogEventType.connectivityOffline,
        message: isConnected
            ? 'Connectivity is online.'
            : 'Connectivity is offline.',
      ),
    );
  }
}
