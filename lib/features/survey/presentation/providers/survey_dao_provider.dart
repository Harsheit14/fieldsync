import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldsync/core/providers/database_provider.dart';
import 'package:fieldsync/features/survey/data/local/dao/survey_dao.dart';

final surveyDaoProvider = Provider<SurveyDao>((ref) {
  return SurveyDao(ref.watch(databaseProvider));
});
