enum SurveyValidationField { farmerName, cropType, fieldArea }

enum SurveyValidationError {
  farmerNameRequired,
  cropTypeRequired,
  fieldAreaMustBeGreaterThanZero,
}

class SurveyValidationResult {
  SurveyValidationResult(
    Map<SurveyValidationField, SurveyValidationError> errors,
  ) : errors = Map.unmodifiable(errors);

  final Map<SurveyValidationField, SurveyValidationError> errors;

  bool get isValid => errors.isEmpty;
}

class SurveyValidator {
  const SurveyValidator();

  SurveyValidationResult validate({
    required String farmerName,
    required String cropType,
    required String fieldArea,
  }) {
    final errors = <SurveyValidationField, SurveyValidationError>{};

    if (farmerName.trim().isEmpty) {
      errors[SurveyValidationField.farmerName] =
          SurveyValidationError.farmerNameRequired;
    }
    if (cropType.trim().isEmpty) {
      errors[SurveyValidationField.cropType] =
          SurveyValidationError.cropTypeRequired;
    }

    final parsedFieldArea = double.tryParse(fieldArea);
    if (parsedFieldArea == null || parsedFieldArea <= 0) {
      errors[SurveyValidationField.fieldArea] =
          SurveyValidationError.fieldAreaMustBeGreaterThanZero;
    }

    return SurveyValidationResult(errors);
  }
}
