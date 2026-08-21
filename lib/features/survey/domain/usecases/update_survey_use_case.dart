import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/domain/repositories/survey_repository.dart';

class UpdateSurveyUseCase {
  UpdateSurveyUseCase(this._repository);

  final SurveyRepository _repository;

  Future<void> execute(SurveyEntity survey) {
    return _repository.updateSurvey(survey);
  }
}
