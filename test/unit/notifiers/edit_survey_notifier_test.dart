import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/domain/usecases/update_survey_use_case.dart';
import 'package:fieldsync/features/survey/presentation/notifiers/edit_survey_notifier.dart';
import 'package:fieldsync/features/survey/presentation/state/edit_survey_state.dart';
import 'package:fieldsync/features/survey/presentation/providers/survey_use_case_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mocks/sync_mocks.dart';

class CapturingUpdateSurveyUseCase extends UpdateSurveyUseCase {
  CapturingUpdateSurveyUseCase() : super(MockSurveyRepository());

  SurveyEntity? capturedSurvey;
  Object? failure;

  @override
  Future<void> execute(SurveyEntity survey) async {
    capturedSurvey = survey;
    if (failure != null) {
      throw failure!;
    }
  }
}

void main() {
  test('preserves the existing survey id and photo paths when updating', () async {
    final useCase = CapturingUpdateSurveyUseCase();
    final container = ProviderContainer(
      overrides: [
        updateSurveyUseCaseProvider.overrideWith((ref) => useCase),
      ],
    );
    addTearDown(container.dispose);

    final originalSurvey = SurveyEntity(
      id: 'survey-1',
      farmerName: 'Ada Farmer',
      cropType: 'Wheat',
      fieldArea: 12.5,
      latitude: 12.34,
      longitude: 56.78,
      photoPaths: const ['/tmp/fieldsync-photo.jpg'],
      status: 'active',
      createdAt: DateTime.utc(2025, 1, 1, 12),
      updatedAt: DateTime.utc(2025, 1, 1, 12),
    );

    await container.read(editSurveyNotifierProvider.notifier).updateSurvey(
      originalSurvey: originalSurvey,
      farmerName: 'Grace Farmer',
      cropType: 'Corn',
      fieldArea: '18.75',
      photoPaths: originalSurvey.photoPaths,
      latitude: originalSurvey.latitude,
      longitude: originalSurvey.longitude,
    );

    expect(useCase.capturedSurvey?.id, originalSurvey.id);
    expect(useCase.capturedSurvey?.photoPaths, originalSurvey.photoPaths);
    expect(useCase.capturedSurvey?.farmerName, 'Grace Farmer');
    expect(container.read(editSurveyNotifierProvider), isA<EditSurveySuccess>());
  });

  test('surfaces update failures through the notifier state', () async {
    final useCase = CapturingUpdateSurveyUseCase()
      ..failure = StateError('database unavailable');
    final container = ProviderContainer(
      overrides: [
        updateSurveyUseCaseProvider.overrideWith((ref) => useCase),
      ],
    );
    addTearDown(container.dispose);

    final originalSurvey = SurveyEntity(
      id: 'survey-1',
      farmerName: 'Ada Farmer',
      cropType: 'Wheat',
      fieldArea: 12.5,
      latitude: 12.34,
      longitude: 56.78,
      photoPaths: const [],
      status: 'active',
      createdAt: DateTime.utc(2025, 1, 1, 12),
      updatedAt: DateTime.utc(2025, 1, 1, 12),
    );

    await container.read(editSurveyNotifierProvider.notifier).updateSurvey(
      originalSurvey: originalSurvey,
      farmerName: 'Grace Farmer',
      cropType: 'Corn',
      fieldArea: '18.75',
      photoPaths: originalSurvey.photoPaths,
      latitude: originalSurvey.latitude,
      longitude: originalSurvey.longitude,
    );

    expect(container.read(editSurveyNotifierProvider), isA<EditSurveyFailure>());
  });
}