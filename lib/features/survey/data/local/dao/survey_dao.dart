import 'package:drift/drift.dart';
import 'package:fieldsync/core/database/app_database.dart';
import 'package:fieldsync/features/survey/data/local/tables/surveys.dart';

part 'survey_dao.g.dart';

@DriftAccessor(tables: [Surveys])
class SurveyDao extends DatabaseAccessor<AppDatabase> with _$SurveyDaoMixin {
  SurveyDao(super.db);

  Future<int> insertSurvey(SurveysCompanion survey) {
    return into(surveys).insert(survey);
  }

  Future<bool> updateSurvey(SurveysCompanion survey) {
    return update(surveys).replace(survey);
  }

  Future<int> markSurveyDeleted(String id) {
    return (update(surveys)..where((survey) => survey.id.equals(id))).write(
      SurveysCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<Survey?> getSurveyById(String id) {
    return (select(
      surveys,
    )..where((survey) => survey.id.equals(id))).getSingleOrNull();
  }

  Stream<List<Survey>> watchAllSurveys() {
    return (select(
      surveys,
    )..where((survey) => survey.isDeleted.equals(false))).watch();
  }
}
