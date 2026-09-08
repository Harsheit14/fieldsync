import 'package:fieldsync/features/survey/domain/usecases/create_survey_use_case.dart';
import 'package:fieldsync/features/survey/domain/usecases/delete_survey_use_case.dart';
import 'package:fieldsync/features/survey/domain/usecases/update_survey_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures/sync_fixtures.dart';
import '../../helpers/mocks/sync_mocks.dart';

void main() {
  late MockSurveyRepository repository;

  setUp(() {
    repository = MockSurveyRepository();
  });

  test('CreateSurveyUseCase delegates to the repository', () async {
    final survey = SyncFixtures.survey();
    when(() => repository.createSurvey(survey)).thenAnswer((_) async {});

    await CreateSurveyUseCase(repository).execute(survey);

    verify(() => repository.createSurvey(survey)).called(1);
  });

  test('UpdateSurveyUseCase delegates to the repository', () async {
    final survey = SyncFixtures.survey();
    when(() => repository.updateSurvey(survey)).thenAnswer((_) async {});

    await UpdateSurveyUseCase(repository).execute(survey);

    verify(() => repository.updateSurvey(survey)).called(1);
  });

  test('DeleteSurveyUseCase delegates to the repository', () async {
    when(() => repository.deleteSurvey('survey-1')).thenAnswer((_) async {});

    await DeleteSurveyUseCase(repository).execute('survey-1');

    verify(() => repository.deleteSurvey('survey-1')).called(1);
  });
}
