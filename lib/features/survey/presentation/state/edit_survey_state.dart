import 'package:fieldsync/features/survey/presentation/state/validation_state.dart';

sealed class EditSurveyState {
  const EditSurveyState();
}

final class EditSurveyIdle extends EditSurveyState {
  const EditSurveyIdle();
}

final class EditSurveyLoading extends EditSurveyState {
  const EditSurveyLoading();
}

final class EditSurveySuccess extends EditSurveyState {
  const EditSurveySuccess();
}

final class EditSurveyValidationFailure extends EditSurveyState {
  const EditSurveyValidationFailure(this.validation);

  final ValidationState validation;
}

final class EditSurveyFailure extends EditSurveyState {
  const EditSurveyFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
