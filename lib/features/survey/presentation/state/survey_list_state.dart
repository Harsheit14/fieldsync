import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';

sealed class SurveyListState {
  const SurveyListState();
}

final class SurveyListLoading extends SurveyListState {
  const SurveyListLoading();
}

final class SurveyListEmpty extends SurveyListState {
  const SurveyListEmpty();
}

final class SurveyListLoaded extends SurveyListState {
  const SurveyListLoaded(this.surveys);

  final List<SurveyEntity> surveys;
}

final class SurveyListError extends SurveyListState {
  const SurveyListError(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
