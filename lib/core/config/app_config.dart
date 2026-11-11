import 'dart:io';

/// Build-time configuration injected with `--dart-define-from-file=env.json`.
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

  static Uri resolveGitHubApiUri(String baseUrl, String path) =>
      Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/').resolve(path);

  static Map<String, String> githubApiHeaders(String accessToken) =>
      <String, String>{
        HttpHeaders.acceptHeader: 'application/vnd.github+json',
        HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        'X-GitHub-Api-Version': '2022-11-28',
      };
}
