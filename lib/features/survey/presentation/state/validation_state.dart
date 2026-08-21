import 'package:fieldsync/features/survey/domain/validation/survey_validator.dart';

class ValidationState {
  const ValidationState._(this.errors);

  const ValidationState.valid() : errors = const {};

  factory ValidationState.fromResult(SurveyValidationResult result) {
    return ValidationState._(result.errors);
  }

  final Map<SurveyValidationField, SurveyValidationError> errors;

  String? messageFor(SurveyValidationField field) {
    return switch (errors[field]) {
      SurveyValidationError.farmerNameRequired => 'Enter the farmer name',
      SurveyValidationError.cropTypeRequired => 'Enter the crop type',
      SurveyValidationError.fieldAreaMustBeGreaterThanZero =>
        'Field area must be greater than zero',
      null => null,
    };
  }
}
