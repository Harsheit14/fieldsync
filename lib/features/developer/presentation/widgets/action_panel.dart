import 'package:flutter/material.dart';

class ActionPanel extends StatelessWidget {
  const ActionPanel({
    super.key,
    required this.onForceSync,
    required this.onClearCompletedOperations,
    required this.onExportLogs,
    required this.onResetMetrics,
  });

  final VoidCallback onForceSync;
  final VoidCallback onClearCompletedOperations;
  final VoidCallback onExportLogs;
  final VoidCallback onResetMetrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Developer actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: onForceSync,
                  child: const Text('Force sync'),
                ),
                OutlinedButton(
                  onPressed: onClearCompletedOperations,
                  child: const Text('Clear completed operations'),
                ),
                OutlinedButton(
                  onPressed: onExportLogs,
                  child: const Text('Export logs'),
                ),
                OutlinedButton(
                  onPressed: onResetMetrics,
                  child: const Text('Reset metrics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
