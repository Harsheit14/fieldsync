import 'package:fieldsync/features/sync/data/policies/exponential_backoff_retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures/sync_fixtures.dart';

void main() {
  const policy = ExponentialBackoffRetryPolicy();

  test('uses exponential retry delays', () {
    expect(policy.nextDelay(1), const Duration(seconds: 2));
    expect(policy.nextDelay(3), const Duration(seconds: 8));
  });

  test('retries retryable failures up to the retry limit', () {
    expect(policy.canRetry(4, SyncFixtures.retryResult), isTrue);
    expect(policy.canRetry(5, SyncFixtures.retryResult), isFalse);
    expect(policy.canRetry(0, SyncFixtures.successResult), isFalse);
  });
}
