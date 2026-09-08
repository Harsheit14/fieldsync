import 'package:fieldsync/features/sync/domain/services/synchronization_service.dart';

class BackgroundSyncRunner {
  const BackgroundSyncRunner(this._synchronizationService);

  final SynchronizationService _synchronizationService;

  Future<void> run() {
    return _synchronizationService.synchronizeOnce();
  }
}
