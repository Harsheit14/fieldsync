import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldsync/features/survey/data/mappers/survey_mapper.dart';
import 'package:fieldsync/features/survey/data/repositories/survey_repository_impl.dart';
import 'package:fieldsync/features/survey/domain/repositories/survey_repository.dart';
import 'package:fieldsync/features/survey/presentation/providers/survey_dao_provider.dart';
import 'package:fieldsync/features/sync/presentation/providers/sync_logger_provider.dart';

final surveyMapperProvider = Provider<SurveyMapper>((ref) {
  return const SurveyMapper();
});

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  return SurveyRepositoryImpl(
    ref.watch(surveyDaoProvider),
    ref.watch(surveyMapperProvider),
    ref.watch(syncLoggerProvider),
  );
});
