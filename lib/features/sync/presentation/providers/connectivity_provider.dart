import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldsync/features/sync/data/services/connectivity_service_impl.dart';
import 'package:fieldsync/features/sync/domain/services/connectivity_service.dart';
import 'package:fieldsync/features/sync/presentation/providers/sync_logger_provider.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityServiceImpl(Connectivity(), ref.watch(syncLoggerProvider));
});

final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).watchConnectivity();
});

final currentConnectivityProvider = FutureProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).isConnected();
});
