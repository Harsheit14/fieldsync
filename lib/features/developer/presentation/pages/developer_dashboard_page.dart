import 'package:fieldsync/features/developer/presentation/widgets/action_panel.dart';
import 'package:fieldsync/features/developer/presentation/widgets/metrics_card.dart';
import 'package:fieldsync/features/developer/presentation/widgets/pending_operations_card.dart';
import 'package:fieldsync/features/developer/presentation/widgets/sync_logs_card.dart';
import 'package:fieldsync/features/developer/presentation/widgets/sync_status_card.dart';
import 'package:fieldsync/features/sync/presentation/providers/connectivity_provider.dart';
import 'package:fieldsync/features/sync/presentation/providers/sync_logger_provider.dart';
import 'package:fieldsync/features/sync/presentation/providers/sync_metrics_provider.dart';
import 'package:fieldsync/features/sync/presentation/providers/sync_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debug-only visualization of the synchronization engine's observed state.
class DeveloperDashboardPage extends ConsumerWidget {
  const DeveloperDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStreamProvider).valueOrNull;
    final isSynchronizing = ref.watch(syncStatusProvider).valueOrNull;
    final metrics = ref.watch(syncMetricsProvider).valueOrNull;
    final operations = ref.watch(pendingOperationsProvider).valueOrNull ?? [];
    final logs = ref.watch(syncLogsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Developer dashboard')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SyncStatusCard(
              isConnected: connectivity,
              isSynchronizing: isSynchronizing,
              metrics: metrics,
            ),
            const SizedBox(height: 12),
            if (metrics != null)
              MetricsCard(metrics: metrics)
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Loading sync metrics...'),
                ),
              ),
            const SizedBox(height: 12),
            PendingOperationsCard(operations: operations),
            const SizedBox(height: 12),
            SyncLogsCard(logs: logs),
            const SizedBox(height: 12),
            ActionPanel(
              onForceSync: () => _forceSync(context),
              onClearCompletedOperations: () =>
                  _clearCompletedOperations(context),
              onExportLogs: () => _exportLogs(context),
              onResetMetrics: () => _resetMetrics(context),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder until SyncCoordinator exposes an explicit force-sync command.
  void _forceSync(BuildContext context) {
    _showUnavailable(context, 'Force sync is not available yet.');
  }

  // Placeholder until the outbox exposes a completed-operation cleanup command.
  void _clearCompletedOperations(BuildContext context) {
    _showUnavailable(
      context,
      'Clearing completed operations is not available yet.',
    );
  }

  // Placeholder until SyncLogger has an export implementation.
  void _exportLogs(BuildContext context) {
    _showUnavailable(context, 'Log export is not available yet.');
  }

  // Placeholder until the metrics service supports resettable aggregation.
  void _resetMetrics(BuildContext context) {
    _showUnavailable(context, 'Resetting metrics is not available yet.');
  }

  void _showUnavailable(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
