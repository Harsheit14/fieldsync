import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures/sync_fixtures.dart';

void main() {
  test(
    'stores, streams, and clears immutable structured log records',
    () async {
      final logger = SyncLoggerImpl();
      final entry = SyncFixtures.log();

      await logger.log(entry);
      expect(await logger.watchLogs().first, [entry]);

      await logger.clearLogs();
      expect(await logger.watchLogs().first, isEmpty);
    },
  );

  test('protects log metadata from later mutation', () {
    final metadata = <String, Object?>{'attempt': 1};
    final entry = SyncLogEntry(
      timestamp: SyncFixtures.timestamp,
      eventType: SyncLogEventType.syncStarted,
      message: 'Started',
      metadata: metadata,
    );

    metadata['attempt'] = 2;

    expect(entry.metadata, {'attempt': 1});
  });
}
