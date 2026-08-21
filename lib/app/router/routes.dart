class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String createSurvey = '/create-survey';
  static const String editSurvey = '/edit-survey/:surveyId';
  static const String developerDashboard = '/developer-dashboard';

  static String editSurveyFor(String surveyId) => '/edit-survey/$surveyId';
}