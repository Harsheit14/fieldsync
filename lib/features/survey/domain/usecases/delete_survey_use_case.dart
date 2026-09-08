import 'package:fieldsync/features/survey/domain/repositories/survey_repository.dart';

class DeleteSurveyUseCase {
  DeleteSurveyUseCase(this._repository);

  final SurveyRepository _repository;

  Future<void> execute(String id) {
    return _repository.deleteSurvey(id);
  }
}
