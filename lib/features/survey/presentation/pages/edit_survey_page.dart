import 'package:fieldsync/app/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fieldsync/features/camera/presentation/providers/camera_provider.dart';
import 'package:fieldsync/features/location/presentation/providers/location_provider.dart';
import 'package:fieldsync/features/survey/presentation/notifiers/edit_survey_notifier.dart';
import 'package:fieldsync/features/survey/presentation/providers/survey_use_case_providers.dart';
import 'package:fieldsync/features/survey/presentation/state/edit_survey_state.dart';
import 'package:fieldsync/features/survey/presentation/state/validation_state.dart';
import 'package:fieldsync/features/survey/presentation/widgets/survey_form.dart';

class EditSurveyPage extends ConsumerWidget {
  const EditSurveyPage({super.key, required this.surveyId});

  final String surveyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surveyAsync = ref.watch(surveyByIdProvider(surveyId));

    ref.listen<EditSurveyState>(
      editSurveyNotifierProvider,
      (previous, next) {
        switch (next) {
          case EditSurveySuccess():
            context.go(AppRoutes.home);

          case EditSurveyFailure(:final error):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Unable to update survey: $error',
                ),
              ),
            );

          case EditSurveyIdle() ||
                EditSurveyLoading() ||
                EditSurveyValidationFailure():
            break;
        }
      },
    );

    final state = ref.watch(editSurveyNotifierProvider);

    final validationState = switch (state) {
      EditSurveyValidationFailure(:final validation) => validation,
      _ => const ValidationState.valid(),
    };

    final getCurrentLocation =
        ref.read(getCurrentLocationUseCaseProvider);

    final captureAndStoreImage =
        ref.read(captureAndStoreImageUseCaseProvider);

    return switch (surveyAsync) {
      AsyncData(:final value) when value != null => Scaffold(
        appBar: AppBar(
          title: const Text('Edit survey'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SurveyForm(
                  initialSurvey: value,
                  submitLabel: 'Save changes',
                  isSubmitting: state is EditSurveyLoading,
                  validationState: validationState,

                  onCaptureLocation: () async {
                    try {
                      return await getCurrentLocation();
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString(),
                            ),
                          ),
                        );
                      }

                      return null;
                    }
                  },

                  onAddPhoto: () async {
                    try {
                      final storedFile =
                          await captureAndStoreImage();

                      return storedFile.path;
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString(),
                            ),
                          ),
                        );
                      }

                      return null;
                    }
                  },

                  onSubmit: (data) {
                    ref
                        .read(editSurveyNotifierProvider.notifier)
                        .updateSurvey(
                          originalSurvey: value,
                          farmerName: data.farmerName,
                          cropType: data.cropType,
                          fieldArea: data.fieldArea,
                          latitude: data.latitude,
                          longitude: data.longitude,
                          photoPaths: data.photoPaths,
                        );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      AsyncData() => const _SurveyNotFoundPage(),
      AsyncError(:final error) => _SurveyLoadError(error: error),
      _ => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

class _SurveyNotFoundPage extends StatelessWidget {
  const _SurveyNotFoundPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Survey not found')),
    );
  }
}

class _SurveyLoadError extends StatelessWidget {
  const _SurveyLoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit survey'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Unable to load survey: $error'),
        ),
      ),
    );
  }
}