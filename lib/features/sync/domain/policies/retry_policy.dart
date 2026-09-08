import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';

abstract class RetryPolicy {
  Duration nextDelay(int retryCount);

  bool canRetry(int retryCount, SyncResult result);
}