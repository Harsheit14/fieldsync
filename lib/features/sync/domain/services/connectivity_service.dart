abstract class ConnectivityService {
  Stream<bool> watchConnectivity();

  Future<bool> isConnected();
}