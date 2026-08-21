import 'package:fieldsync/features/survey/domain/validation/survey_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = SurveyValidator();

  group('SurveyValidator', () {
    test('accepts valid survey input', () {
      final result = validator.validate(
        farmerName: 'Ada',
        cropType: 'Wheat',
        fieldArea: '1.5',
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('reports every invalid field', () {
      final result = validator.validate(
        farmerName: ' ',
        cropType: '',
        fieldArea: '0',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors,
        containsPair(
          SurveyValidationField.farmerName,
          SurveyValidationError.farmerNameRequired,
        ),
      );
      expect(
        result.errors,
        containsPair(
          SurveyValidationField.cropType,
          SurveyValidationError.cropTypeRequired,
        ),
      );
      expect(
        result.errors,
        containsPair(
          SurveyValidationField.fieldArea,
          SurveyValidationError.fieldAreaMustBeGreaterThanZero,
        ),
      );
    });
  });
}
