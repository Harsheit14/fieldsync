import 'package:fieldsync/features/developer/presentation/pages/developer_dashboard_page.dart';
import 'package:fieldsync/features/survey/presentation/pages/edit_survey_page.dart';
import 'package:fieldsync/features/survey/presentation/pages/create_survey_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/pages/home_page.dart';
import 'routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),

      GoRoute(
        path: AppRoutes.createSurvey,
        builder: (context, state) => const CreateSurveyPage(),
      ),

      GoRoute(
        path: AppRoutes.editSurvey,
        builder: (context, state) {
          final surveyId = state.pathParameters['surveyId'];
          if (surveyId == null || surveyId.isEmpty) {
            return const _MissingSurveyRoutePage();
          }

          return EditSurveyPage(surveyId: surveyId);
        },
      ),

      if (kDebugMode)
        GoRoute(
          path: AppRoutes.developerDashboard,
          builder: (context, state) =>
              const DeveloperDashboardPage(),
        ),
    ],
  );

  static GoRouter get router => _router;
}

class _MissingSurveyRoutePage extends StatelessWidget {
  const _MissingSurveyRoutePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Missing survey id'),
      ),
    );
  }
}