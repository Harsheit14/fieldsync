import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/domain/usecases/get_survey_use_case.dart';
import 'package:fieldsync/features/survey/domain/usecases/create_survey_use_case.dart';
import 'package:fieldsync/features/survey/domain/usecases/delete_survey_use_case.dart';
import 'package:fieldsync/features/survey/domain/usecases/update_survey_use_case.dart';
import 'package:fieldsync/features/survey/domain/usecases/watch_surveys_use_case.dart';
import 'package:fieldsync/features/survey/presentation/providers/survey_repository_provider.dart';

final createSurveyUseCaseProvider = Provider<CreateSurveyUseCase>((ref) {
  return CreateSurveyUseCase(ref.watch(surveyRepositoryProvider));
});

final updateSurveyUseCaseProvider = Provider<UpdateSurveyUseCase>((ref) {
  return UpdateSurveyUseCase(ref.watch(surveyRepositoryProvider));
});

final getSurveyUseCaseProvider = Provider<GetSurveyUseCase>((ref) {
  return GetSurveyUseCase(ref.watch(surveyRepositoryProvider));
});

final deleteSurveyUseCaseProvider = Provider<DeleteSurveyUseCase>((ref) {
  return DeleteSurveyUseCase(ref.watch(surveyRepositoryProvider));
});

final watchSurveysUseCaseProvider = Provider<WatchSurveysUseCase>((ref) {
  return WatchSurveysUseCase(ref.watch(surveyRepositoryProvider));
});

final surveyByIdProvider = FutureProvider.family<SurveyEntity?, String>(
  (ref, surveyId) {
    return ref.watch(getSurveyUseCaseProvider).execute(surveyId);
  },
);
