import 'package:fieldsync/features/sync/background/background_sync_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks/sync_mocks.dart';

void main() {
  late MockSynchronizationService synchronizationService;
  late BackgroundSyncRunner runner;

  setUp(() {
    synchronizationService = MockSynchronizationService();
    runner = BackgroundSyncRunner(synchronizationService);
  });

  test('run delegates synchronization to SynchronizationService', () async {
    when(
      () => synchronizationService.synchronizeOnce(),
    ).thenAnswer((_) async {});

    await runner.run();

    verify(() => synchronizationService.synchronizeOnce()).called(1);
  });

  test('run propagates synchronization failure', () async {
    final error = Exception('Synchronization failed.');

    when(() => synchronizationService.synchronizeOnce()).thenThrow(error);

    expect(runner.run, throwsA(same(error)));

    verify(() => synchronizationService.synchronizeOnce()).called(1);
  });
}
