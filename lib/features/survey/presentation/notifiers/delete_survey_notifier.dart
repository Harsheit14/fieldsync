import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fieldsync/features/survey/domain/entities/survey_entity.dart';
import 'package:fieldsync/features/survey/presentation/providers/survey_use_case_providers.dart';

final deleteSurveyNotifierProvider =
    NotifierProvider<DeleteSurveyNotifier, Set<String>>(
      DeleteSurveyNotifier.new,
    );

class DeleteSurveyNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    return const <String>{};
  }

  Future<void> deleteSurvey(SurveyEntity survey) async {
    if (state.contains(survey.id)) {
      return;
    }

    state = {...state, survey.id};

    try {
      await ref.read(deleteSurveyUseCaseProvider).execute(survey.id);
    } finally {
      if (state.contains(survey.id)) {
        final nextState = Set<String>.from(state)..remove(survey.id);
        state = nextState;
      }
    }
  }
}