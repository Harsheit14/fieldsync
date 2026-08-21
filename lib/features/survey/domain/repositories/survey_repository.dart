import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';

abstract class SurveyRepository {
  Future<void> createSurvey(SurveyEntity survey);

  Future<void> updateSurvey(SurveyEntity survey);

  Future<void> deleteSurvey(String id);

  Future<SurveyEntity?> getSurveyById(String id);

  Stream<List<SurveyEntity>> watchAllSurveys();
}
