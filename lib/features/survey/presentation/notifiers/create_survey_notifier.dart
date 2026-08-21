import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/domain/usecases/create_survey_use_case.dart';
import 'package:fieldsync/features/survey/domain/validation/survey_validator.dart';
import 'package:fieldsync/features/survey/presentation/providers/survey_use_case_providers.dart';
import 'package:fieldsync/features/survey/presentation/state/create_survey_state.dart';
import 'package:fieldsync/features/survey/presentation/state/validation_state.dart';
import 'package:uuid/uuid.dart';

final createSurveyNotifierProvider =
    NotifierProvider<CreateSurveyNotifier, CreateSurveyState>(
      CreateSurveyNotifier.new,
    );

class CreateSurveyNotifier extends Notifier<CreateSurveyState> {
  late final CreateSurveyUseCase _createSurvey;

  static const _validator = SurveyValidator();

  @override
  CreateSurveyState build() {
    _createSurvey = ref.watch(createSurveyUseCaseProvider);
    return const CreateSurveyIdle();
  }

  Future<void> createSurvey({
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
      state = CreateSurveyValidationFailure(
        ValidationState.fromResult(validationResult),
      );
      return;
    }

    state = const CreateSurveyLoading();

    final now = DateTime.now();

    final survey = SurveyEntity(
      id: const Uuid().v4(),
      farmerName: farmerName,
      cropType: cropType,
      fieldArea: double.parse(fieldArea),
      latitude: latitude ?? 0,
      longitude: longitude ?? 0,
      photoPaths: List.unmodifiable(photoPaths),
      status: 'draft',
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _createSurvey.execute(survey);

      state = const CreateSurveySuccess();
    } catch (error, stackTrace) {
      state = CreateSurveyFailure(
        error,
        stackTrace,
      );
    }
  }
}