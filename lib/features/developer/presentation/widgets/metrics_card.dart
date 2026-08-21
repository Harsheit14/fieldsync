import 'package:fieldsync/features/sync/domain/metrics/sync_metrics.dart';
import 'package:flutter/material.dart';

class MetricsCard extends StatelessWidget {
  const MetricsCard({super.key, required this.metrics});

  final SyncMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final values = <String, String>{
      'Queue size': '${metrics.queueSize}',
      'Pending': '${metrics.pendingCount}',
      'Processing': '${metrics.processingCount}',
      'Completed': '${metrics.completedCount}',
      'Failed': '${metrics.failedCount}',
      'Retry scheduled': '${metrics.retryScheduledCount}',
      'Average duration': _formatDuration(metrics.averageSyncDuration),
      'Success rate': _formatRate(metrics.successRate),
      'Failure rate': _formatRate(metrics.failureRate),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sync metrics', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              children: values.entries
                  .map(
                    (entry) => SizedBox(
                      width: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key),
                          Text(
                            entry.value,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 1) {
      return '${duration.inMilliseconds} ms';
    }
    return '${duration.inSeconds}s';
  }

  String _formatRate(double rate) => '${(rate * 100).toStringAsFixed(1)}%';
}
