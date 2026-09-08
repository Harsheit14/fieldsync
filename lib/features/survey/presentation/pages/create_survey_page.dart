import 'package:fieldsync/app/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fieldsync/features/camera/presentation/providers/camera_provider.dart';
import 'package:fieldsync/features/location/presentation/providers/location_provider.dart';
import 'package:fieldsync/features/survey/presentation/notifiers/create_survey_notifier.dart';
import 'package:fieldsync/features/survey/presentation/state/create_survey_state.dart';
import 'package:fieldsync/features/survey/presentation/state/validation_state.dart';
import 'package:fieldsync/features/survey/presentation/widgets/survey_form.dart';

class CreateSurveyPage extends ConsumerWidget {
  const CreateSurveyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<CreateSurveyState>(
      createSurveyNotifierProvider,
      (previous, next) {
        switch (next) {
          case CreateSurveySuccess():
            context.go(AppRoutes.home);

          case CreateSurveyFailure(:final error):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Unable to save survey: $error',
                ),
              ),
            );

          case CreateSurveyIdle() ||
                CreateSurveyLoading() ||
                CreateSurveyValidationFailure():
            break;
        }
      },
    );

    final state = ref.watch(createSurveyNotifierProvider);

    final validationState = switch (state) {
      CreateSurveyValidationFailure(:final validation) => validation,
      _ => const ValidationState.valid(),
    };

    final getCurrentLocation =
        ref.read(getCurrentLocationUseCaseProvider);

    final captureAndStoreImage =
        ref.read(captureAndStoreImageUseCaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create survey'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SurveyForm(
                isSubmitting: state is CreateSurveyLoading,
                validationState: validationState,

                onCaptureLocation: () async {
                  try {
                    return await getCurrentLocation();
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error.toString()),
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
                          content: Text(error.toString()),
                        ),
                      );
                    }

                    return null;
                  }
                },

                onSubmit: (data) {
                  ref
                      .read(
                        createSurveyNotifierProvider.notifier,
                      )
                      .createSurvey(
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
    );
  }
}