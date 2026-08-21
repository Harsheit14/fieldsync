import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/domain/repositories/survey_repository.dart';

class GetSurveyUseCase {
  GetSurveyUseCase(this._repository);

  final SurveyRepository _repository;

  Future<SurveyEntity?> execute(String id) {
    return _repository.getSurveyById(id);
  }
}
