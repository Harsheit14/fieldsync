import 'package:fieldsync/app/router/routes.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/presentation/notifiers/delete_survey_notifier.dart';
import 'package:fieldsync/features/survey/presentation/controllers/survey_list_controller.dart';
import 'package:fieldsync/features/survey/presentation/state/survey_list_state.dart';
import 'package:fieldsync/features/survey/presentation/widgets/empty_surveys_widget.dart';
import 'package:fieldsync/features/survey/presentation/widgets/loading_surveys_widget.dart';
import 'package:fieldsync/features/survey/presentation/widgets/survey_card.dart';
import 'package:fieldsync/features/sync/presentation/providers/sync_metrics_provider.dart';
import 'package:fieldsync/features/sync/presentation/providers/sync_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fieldsync/features/sync/domain/metrics/sync_metrics.dart';
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(surveyListControllerProvider);
    final deletingIds = ref.watch(deleteSurveyNotifierProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final syncMetrics = ref.watch(syncMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          if (kDebugMode)
            IconButton(
              onPressed: () =>
                  context.go(AppRoutes.developerDashboard),
              icon: const Icon(Icons.developer_mode),
              tooltip: 'Developer dashboard',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _SyncStatusCard(
              syncStatus: syncStatus,
              syncMetrics: syncMetrics,
            ),
            Expanded(
              child: switch (state) {
                SurveyListLoading() => const LoadingSurveysWidget(),
                SurveyListEmpty() => const _DashboardEmptyState(),
                SurveyListLoaded(:final surveys) => _DashboardSurveyList(
                  surveys: surveys,
                  deletingIds: deletingIds,
                  onDelete: (survey) =>
                      _confirmDeleteSurvey(context, ref, survey),
                ),
                SurveyListError(:final error) =>
                  _DashboardError(error: error),
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push(AppRoutes.createSurvey),
        icon: const Icon(Icons.add),
        label: const Text('New Survey'),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({
    required this.syncStatus,
    required this.syncMetrics,
  });

  final AsyncValue<bool> syncStatus;
  final AsyncValue<SyncMetrics> syncMetrics;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isSyncing = syncStatus.valueOrNull ?? false;
    final metrics = syncMetrics.valueOrNull;

    final queueSize = metrics?.queueSize ?? 0;
    final failedCount = metrics?.failedCount ?? 0;
    final retryCount = metrics?.retryScheduledCount ?? 0;

    final statusText = isSyncing
        ? 'Syncing data...'
        : queueSize > 0
            ? 'Waiting to sync'
            : 'All data synchronized';

    final statusIcon = isSyncing
        ? Icons.sync
        : queueSize > 0
            ? Icons.cloud_upload_outlined
            : Icons.cloud_done_outlined;

    final statusColor = failedCount > 0
        ? colorScheme.error
        : isSyncing
            ? colorScheme.primary
            : colorScheme.secondary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildDetails(
                    queueSize,
                    failedCount,
                    retryCount,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isSyncing)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  String _buildDetails(
    int queueSize,
    int failedCount,
    int retryCount,
  ) {
    final details = <String>[];

    if (queueSize > 0) {
      details.add('$queueSize queued');
    }

    if (retryCount > 0) {
      details.add('$retryCount retrying');
    }

    if (failedCount > 0) {
      details.add('$failedCount failed');
    }

    if (details.isEmpty) {
      return 'Local changes are synchronized with the server.';
    }

    return details.join(' • ');
  }
}

class _DashboardSurveyList extends StatelessWidget {
  const _DashboardSurveyList({
    required this.surveys,
    required this.deletingIds,
    required this.onDelete,
  });

  final List<SurveyEntity> surveys;
  final Set<String> deletingIds;
  final ValueChanged<SurveyEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: surveys.length,
          itemBuilder: (context, index) => SurveyCard(
            survey: surveys[index],
            onEdit: () => context.push(
              AppRoutes.editSurveyFor(surveys[index].id),
            ),
            onDelete: () => onDelete(surveys[index]),
            isDeleteLoading: deletingIds.contains(surveys[index].id),
          ),
          separatorBuilder: (context, index) =>
              const SizedBox(height: 12),
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteSurvey(
  BuildContext context,
  WidgetRef ref,
  SurveyEntity survey,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete survey?'),
        content: Text(
          'Are you sure you want to delete the survey for ${survey.farmerName}?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  try {
    await ref
        .read(deleteSurveyNotifierProvider.notifier)
        .deleteSurvey(survey);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Survey deleted successfully.'),
      ),
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to delete survey: $error'),
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptySurveysWidget(),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load surveys',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}