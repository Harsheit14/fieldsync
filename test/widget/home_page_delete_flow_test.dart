import 'package:fieldsync/app/router/app_router.dart';
import 'package:fieldsync/features/survey/data/local/dao/survey_dao.dart';
import 'package:fieldsync/features/survey/data/mappers/survey_mapper.dart';
import 'package:fieldsync/features/survey/data/repositories/survey_repository_impl.dart';
import 'package:fieldsync/features/survey/presentation/providers/survey_repository_provider.dart';
import 'package:fieldsync/features/sync/data/logger/sync_logger_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake/in_memory_database.dart';
import '../helpers/fixtures/sync_fixtures.dart';

void main() {
  testWidgets('delete confirmation cancels and deletes from dashboard', (
    tester,
  ) async {
    final database = createInMemoryDatabase();
    addTearDown(database.close);
    final repository = SurveyRepositoryImpl(
      SurveyDao(database),
      const SurveyMapper(),
      SyncLoggerImpl(),
    );
    final survey = SyncFixtures.survey();
    await repository.createSurvey(survey);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surveyRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: MaterialApp.router(routerConfig: AppRouter.router),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text(survey.farmerName), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete survey?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text(survey.farmerName), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Survey deleted successfully.'), findsOneWidget);
    expect(find.text(survey.farmerName), findsNothing);
    expect((await SurveyDao(database).getSurveyById(survey.id))?.isDeleted, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}