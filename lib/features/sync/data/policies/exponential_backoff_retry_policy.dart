import 'package:fieldsync/features/sync/domain/entities/sync_result.dart';
import 'package:fieldsync/features/sync/domain/policies/retry_policy.dart';

class ExponentialBackoffRetryPolicy implements RetryPolicy {
  const ExponentialBackoffRetryPolicy();

  static const _maxRetries = 5;

  @override
  Duration nextDelay(int retryCount) {
    return Duration(seconds: 1 << retryCount);
  }

  @override
  bool canRetry(int retryCount, SyncResult result) {
    return result.retryable && retryCount < _maxRetries;
  }
}