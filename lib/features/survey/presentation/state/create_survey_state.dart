import 'package:fieldsync/features/survey/presentation/state/validation_state.dart';

sealed class CreateSurveyState {
  const CreateSurveyState();
}

final class CreateSurveyIdle extends CreateSurveyState {
  const CreateSurveyIdle();
}

final class CreateSurveyLoading extends CreateSurveyState {
  const CreateSurveyLoading();
}

final class CreateSurveySuccess extends CreateSurveyState {
  const CreateSurveySuccess();
}

final class CreateSurveyValidationFailure extends CreateSurveyState {
  const CreateSurveyValidationFailure(this.validation);

  final ValidationState validation;
}

final class CreateSurveyFailure extends CreateSurveyState {
  const CreateSurveyFailure(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}
