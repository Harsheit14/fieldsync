import 'package:fieldsync/features/survey/data/local/dao/survey_dao.dart';
import 'package:fieldsync/features/survey/data/mappers/survey_mapper.dart';
import 'package:fieldsync/features/survey/data/repositories/survey_repository_impl.dart';
import 'package:fieldsync/features/sync/data/local/dao/pending_operations_dao.dart';
import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake/in_memory_database.dart';
import '../../helpers/fixtures/sync_fixtures.dart';

void main() {
  test(
    'creating a survey persists both SQLite survey and pending operation',
    () async {
      final database = createInMemoryDatabase();
      addTearDown(database.close);
      final repository = SurveyRepositoryImpl(
        SurveyDao(database),
        const SurveyMapper(),
        SyncLoggerImpl(),
      );
      final survey = SyncFixtures.survey();

      await repository.createSurvey(survey);

      expect(
        (await SurveyDao(database).getSurveyById(survey.id))?.id,
        survey.id,
      );
      final operations = await PendingOperationsDao(
        database,
      ).watchAllOperations().first;
      expect(operations.single.entityType, 'Survey');
      expect(operations.single.status, 'pending');
    },
  );
}
