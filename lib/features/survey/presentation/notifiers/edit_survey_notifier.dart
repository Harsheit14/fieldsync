import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/domain/usecases/update_survey_use_case.dart';
import 'package:fieldsync/features/survey/domain/validation/survey_validator.dart';
import 'package:fieldsync/features/survey/presentation/providers/survey_use_case_providers.dart';
import 'package:fieldsync/features/survey/presentation/state/edit_survey_state.dart';
import 'package:fieldsync/features/survey/presentation/state/validation_state.dart';

final editSurveyNotifierProvider =
    NotifierProvider<EditSurveyNotifier, EditSurveyState>(
      EditSurveyNotifier.new,
    );

class EditSurveyNotifier extends Notifier<EditSurveyState> {
  late final UpdateSurveyUseCase _updateSurvey;

  static const _validator = SurveyValidator();

  @override
  EditSurveyState build() {
    _updateSurvey = ref.watch(updateSurveyUseCaseProvider);
    return const EditSurveyIdle();
  }

  Future<void> updateSurvey({
    required SurveyEntity originalSurvey,
    required String farmerName,
    required String cropType,
    required String fieldArea,
    required List<String> photoPaths,
    double? latitude,
    double? longitude,
  }) async {
    final validationResult = _validator.validate(
      farmerName: farmerName,
      cropType: cropType,
      fieldArea: fieldArea,
    );

    if (!validationResult.isValid) {
      state = EditSurveyValidationFailure(
        ValidationState.fromResult(validationResult),
      );
      return;
    }

    state = const EditSurveyLoading();

    final updatedSurvey = SurveyEntity(
      id: originalSurvey.id,
      farmerName: farmerName,
      cropType: cropType,
      fieldArea: double.parse(fieldArea),
      latitude: latitude ?? originalSurvey.latitude,
      longitude: longitude ?? originalSurvey.longitude,
      photoPaths: List.unmodifiable(photoPaths),
      status: originalSurvey.status,
      createdAt: originalSurvey.createdAt,
      updatedAt: DateTime.now(),
    );

    try {
      await _updateSurvey.execute(updatedSurvey);
      state = const EditSurveySuccess();
    } catch (error, stackTrace) {
      state = EditSurveyFailure(
        error,
        stackTrace,
      );
    }
  }
}