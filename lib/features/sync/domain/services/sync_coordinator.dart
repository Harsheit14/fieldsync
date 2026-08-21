abstract class SyncCoordinator {
  Future<void> start();

  Future<void> stop();

  bool get isRunning;
}