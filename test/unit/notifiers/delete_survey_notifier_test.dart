import 'dart:async';

import 'package:fieldsync/features/survey/domain/usecases/delete_survey_use_case.dart';
import 'package:fieldsync/features/survey/presentation/notifiers/delete_survey_notifier.dart';
import 'package:fieldsync/features/survey/presentation/providers/survey_use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures/sync_fixtures.dart';
import '../../helpers/mocks/sync_mocks.dart';

class ControllableDeleteSurveyUseCase extends DeleteSurveyUseCase {
  ControllableDeleteSurveyUseCase() : super(MockSurveyRepository());

  String? deletedId;
  Completer<void>? completer;
  Object? failure;

  @override
  Future<void> execute(String id) async {
    deletedId = id;
    if (completer != null) {
      await completer!.future;
    }
    if (failure != null) {
      throw failure!;
    }
  }
}

void main() {
  test('tracks in-progress delete and clears state after success', () async {
    final useCase = ControllableDeleteSurveyUseCase()
      ..completer = Completer<void>();
    final container = ProviderContainer(
      overrides: [
        deleteSurveyUseCaseProvider.overrideWith((ref) => useCase),
      ],
    );
    addTearDown(container.dispose);

    final survey = SyncFixtures.survey();
    final future = container
        .read(deleteSurveyNotifierProvider.notifier)
        .deleteSurvey(survey);

    await Future<void>.delayed(Duration.zero);
    expect(container.read(deleteSurveyNotifierProvider), contains(survey.id));

    useCase.completer!.complete();
    await future;

    expect(useCase.deletedId, survey.id);
    expect(container.read(deleteSurveyNotifierProvider), isEmpty);
  });

  test('clears in-progress state when delete fails', () async {
    final useCase = ControllableDeleteSurveyUseCase()
      ..failure = StateError('database unavailable');
    final container = ProviderContainer(
      overrides: [
        deleteSurveyUseCaseProvider.overrideWith((ref) => useCase),
      ],
    );
    addTearDown(container.dispose);

    final survey = SyncFixtures.survey();

    await expectLater(
      container.read(deleteSurveyNotifierProvider.notifier).deleteSurvey(survey),
      throwsA(isA<StateError>()),
    );

    expect(useCase.deletedId, survey.id);
    expect(container.read(deleteSurveyNotifierProvider), isEmpty);
  });
}