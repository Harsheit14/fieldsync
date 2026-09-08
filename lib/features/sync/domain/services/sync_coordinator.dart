abstract class SyncCoordinator {
  Future<void> start();

  Future<void> stop();

  Future<void> syncNow();

  bool get isRunning;
}