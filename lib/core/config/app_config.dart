import 'env.dart';

class AppConfig {
  AppConfig._(this.env);

  static AppConfig? _instance;

  final Env env;

  static bool get isInitialized => _instance != null;

  static AppConfig get instance {
    final currentInstance = _instance;

    if (currentInstance == null) {
      throw const AppConfigNotInitializedException(
        'AppConfig has not been initialized.',
      );
    }

    return currentInstance;
  }

  String get apiBaseUrl => env.requireString('API_BASE_URL');

  static Future<AppConfig> initialize({
    String fileName = '.env',
    Iterable<String> requiredKeys = const [],
  }) async {
    if (_instance != null) {
      throw const AppConfigAlreadyInitializedException(
        'AppConfig can only be initialized once.',
      );
    }

    final loadedEnv = await Env.load(fileName: fileName);
    final missingKeys = <String>[];

    for (final key in requiredKeys) {
      if (!loadedEnv.contains(key) ||
          loadedEnv.string(key)?.trim().isEmpty == true) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty) {
      throw AppConfigValidationException.missingRequiredKeys(missingKeys);
    }

    final appConfig = AppConfig._(loadedEnv);
    _instance = appConfig;

    return appConfig;
  }
}

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigException: $message';
}

class AppConfigAlreadyInitializedException extends AppConfigException {
  const AppConfigAlreadyInitializedException(super.message);
}

class AppConfigNotInitializedException extends AppConfigException {
  const AppConfigNotInitializedException(super.message);
}

class AppConfigValidationException extends AppConfigException {
  const AppConfigValidationException(super.message, this.missingKeys);

  factory AppConfigValidationException.missingRequiredKeys(
    List<String> missingKeys,
  ) {
    return AppConfigValidationException(
      'Missing required configuration: ${missingKeys.join(', ')}.',
      List.unmodifiable(missingKeys),
    );
  }

  final List<String> missingKeys;
}
