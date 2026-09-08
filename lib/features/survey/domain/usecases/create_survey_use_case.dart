import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/domain/repositories/survey_repository.dart';

class CreateSurveyUseCase {
  CreateSurveyUseCase(this._repository);

  final SurveyRepository _repository;

  Future<void> execute(SurveyEntity survey) {
    return _repository.createSurvey(survey);
  }
}
