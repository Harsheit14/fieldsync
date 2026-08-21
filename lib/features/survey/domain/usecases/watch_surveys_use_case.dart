import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/domain/repositories/survey_repository.dart';

class WatchSurveysUseCase {
  WatchSurveysUseCase(this._repository);

  final SurveyRepository _repository;

  Stream<List<SurveyEntity>> execute() {
    return _repository.watchAllSurveys();
  }
}
