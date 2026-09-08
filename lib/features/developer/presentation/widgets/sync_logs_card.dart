import 'package:fieldsync/features/sync/domain/entities/sync_log_entry.dart';
import 'package:flutter/material.dart';

class SyncLogsCard extends StatelessWidget {
  const SyncLogsCard({super.key, required this.logs});

  final List<SyncLogEntry> logs;

  @override
  Widget build(BuildContext context) {
    final newestFirst = logs.reversed.toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sync logs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (newestFirst.isEmpty)
              const Text('No sync logs recorded.')
            else
              SizedBox(
                height: 320,
                child: ListView.separated(
                  itemCount: newestFirst.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final entry = newestFirst[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.message),
                      subtitle: Text(
                        '${entry.eventType.name} · '
                        '${entry.timestamp.toLocal().toIso8601String()}'
                        '${entry.operationId == null ? '' : '\nOperation: ${entry.operationId}'}',
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
