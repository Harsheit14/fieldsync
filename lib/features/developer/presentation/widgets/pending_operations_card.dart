import 'package:fieldsync/features/sync/domain/entities/pending_operation_entity.dart';
import 'package:flutter/material.dart';

class PendingOperationsCard extends StatelessWidget {
  const PendingOperationsCard({super.key, required this.operations});

  final List<PendingOperationEntity> operations;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending operations (${operations.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (operations.isEmpty)
              const Text('No pending operations.')
            else
              SizedBox(
                height: 260,
                child: ListView.separated(
                  itemCount: operations.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final operation = operations[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${operation.operationType.name} ${operation.entityType}',
                      ),
                      subtitle: Text(
                        'Entity: ${operation.entityId}\n'
                        'Retries: ${operation.retryCount} · '
                        'Created: ${operation.createdAt.toLocal().toIso8601String()}',
                      ),
                      trailing: Text(operation.status.name),
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
