import 'package:fieldsync/app/router/routes.dart';
import 'package:fieldsync/features/storage/domain/usecases/read_file_usecase.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/presentation/controllers/survey_list_controller.dart';
import 'package:fieldsync/features/survey/presentation/notifiers/delete_survey_notifier.dart';
import 'package:fieldsync/features/survey/presentation/state/survey_list_state.dart';
import 'package:fieldsync/features/survey/presentation/widgets/empty_surveys_widget.dart';
import 'package:fieldsync/features/survey/presentation/widgets/loading_surveys_widget.dart';
import 'package:fieldsync/features/survey/presentation/widgets/survey_card.dart';
import 'package:fieldsync/features/storage/presentation/providers/storage_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SurveyListPage extends ConsumerWidget {
  const SurveyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(surveyListControllerProvider);
    final deletingIds = ref.watch(deleteSurveyNotifierProvider);
    final readFileUseCase = ref.watch(readFileUseCaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Surveys')),
      body: switch (state) {
        SurveyListLoading() => const LoadingSurveysWidget(),
        SurveyListEmpty() => const EmptySurveysWidget(),
        SurveyListLoaded(:final surveys) => _SurveyList(
          surveys: surveys,
          deletingIds: deletingIds,
          readFileUseCase: readFileUseCase,
          onEdit: (survey) => context.push(AppRoutes.editSurveyFor(survey.id)),
          onDelete: (survey) => _confirmDeleteSurvey(context, ref, survey),
        ),
        SurveyListError(:final error) => _SurveyListError(error: error),
      },
    );
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
          content: Text('Delete the survey for ${survey.farmerName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
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
        const SnackBar(content: Text('Survey deleted successfully.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete survey: $error')),
      );
    }
  }
}

class _SurveyList extends StatelessWidget {
  const _SurveyList({
    required this.surveys,
    required this.deletingIds,
    required this.readFileUseCase,
    required this.onEdit,
    required this.onDelete,
  });

  final List<SurveyEntity> surveys;
  final Set<String> deletingIds;
  final ReadFileUseCase readFileUseCase;
  final ValueChanged<SurveyEntity> onEdit;
  final ValueChanged<SurveyEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: surveys.length,
              itemBuilder: (context, index) => SurveyCard(
                survey: surveys[index],
                readFileUseCase: readFileUseCase,
                onEdit: () => onEdit(surveys[index]),
                onDelete: () => onDelete(surveys[index]),
                isDeleteLoading: deletingIds.contains(surveys[index].id),
              ),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
          ),
        );
      },
    );
  }
}

class _SurveyListError extends StatelessWidget {
  const _SurveyListError({required this.error});

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
            Icon(Icons.error_outline, color: colorScheme.error, size: 48),
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
