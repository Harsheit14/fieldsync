import 'package:fieldsync/features/sync/domain/metrics/sync_metrics.dart';
import 'package:flutter/material.dart';

class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({
    super.key,
    required this.isConnected,
    required this.isSynchronizing,
    required this.metrics,
  });

  final bool? isConnected;
  final bool? isSynchronizing;
  final SyncMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sync status', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _StatusRow(
              label: 'Connectivity',
              value: isConnected == null
                  ? 'Checking'
                  : isConnected!
                  ? 'Online'
                  : 'Offline',
            ),
            _StatusRow(
              label: 'Current sync state',
              value: isSynchronizing == null
                  ? 'Checking'
                  : isSynchronizing!
                  ? 'Synchronizing'
                  : 'Idle',
            ),
            _StatusRow(
              label: 'Current queue status',
              value: metrics == null
                  ? 'Loading'
                  : '${metrics!.queueSize} operation(s) queued',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value)],
      ),
    );
  }
}
