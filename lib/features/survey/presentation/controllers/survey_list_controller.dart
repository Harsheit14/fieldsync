import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/presentation/providers/survey_use_case_providers.dart';
import 'package:fieldsync/features/survey/presentation/state/survey_list_state.dart';

final surveyListControllerProvider =
    NotifierProvider<SurveyListController, SurveyListState>(
      SurveyListController.new,
    );

class SurveyListController extends Notifier<SurveyListState> {
  @override
  SurveyListState build() {
    final subscription = ref
        .watch(watchSurveysUseCaseProvider)
        .execute()
        .listen(_handleSurveys, onError: _handleError);
    ref.onDispose(subscription.cancel);

    return const SurveyListLoading();
  }

  void _handleSurveys(List<SurveyEntity> surveys) {
    state = surveys.isEmpty
        ? const SurveyListEmpty()
        : SurveyListLoaded(List.unmodifiable(surveys));
  }

  void _handleError(Object error, StackTrace stackTrace) {
    state = SurveyListError(error, stackTrace);
  }
}
