/// Build-time configuration injected with `--dart-define-from-file=env.json`.
///
/// Nothing is hardcoded: missing values are reported by [missingKeys].
abstract final class AppConfig {
  static const String githubClientId = String.fromEnvironment(
    'GITHUB_CLIENT_ID',
  );
  static const String githubClientSecret = String.fromEnvironment(
    'GITHUB_CLIENT_SECRET',
  );
  static const String githubApiBaseUrl = String.fromEnvironment(
    'GITHUB_API_BASE_URL',
    defaultValue: 'https://api.github.com',
  );
  static const String githubWebBaseUrl = String.fromEnvironment(
    'GITHUB_WEB_BASE_URL',
    defaultValue: 'https://github.com',
  );

  /// Names of the required keys that were not provided at build time.
  static List<String> get missingKeys => <String>[
    if (githubClientId.isEmpty) 'GITHUB_CLIENT_ID',
    if (githubClientSecret.isEmpty) 'GITHUB_CLIENT_SECRET',
  ];
}
