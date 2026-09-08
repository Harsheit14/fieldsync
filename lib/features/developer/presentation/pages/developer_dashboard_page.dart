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
      appBar: AppBar(
        title: const Text('Developer dashboard'),
      ),
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
            PendingOperationsCard(
              operations: operations,
            ),
            const SizedBox(height: 12),
            SyncLogsCard(
              logs: logs,
            ),
            const SizedBox(height: 12),
            ActionPanel(
              onForceSync: () => _forceSync(context, ref),
              onClearCompletedOperations: () =>
                  _clearCompletedOperations(context, ref),
              onExportLogs: () => _exportLogs(context),
              onResetMetrics: () => _resetMetrics(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _forceSync(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final connectivity = ref.read(connectivityStreamProvider).valueOrNull;

    if (connectivity != true) {
      _showMessage(
        context,
        'Cannot force sync while offline.',
      );
      return;
    }

    try {
      await ref.read(syncCoordinatorProvider).syncNow();

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'Synchronization triggered.',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'Unable to start synchronization: $error',
      );
    }
  }

  Future<void> _clearCompletedOperations(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final count = await ref
          .read(pendingOperationsRepositoryProvider)
          .clearCompletedOperations();

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        count == 0
            ? 'No completed operations to clear.'
            : 'Cleared $count completed operation(s).',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'Unable to clear completed operations: $error',
      );
    }
  }

  void _exportLogs(BuildContext context) {
    _showMessage(
      context,
      'Log export is not available yet.',
    );
  }

  void _resetMetrics(BuildContext context) {
    _showMessage(
      context,
      'Metrics reset is not available yet.',
    );
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}