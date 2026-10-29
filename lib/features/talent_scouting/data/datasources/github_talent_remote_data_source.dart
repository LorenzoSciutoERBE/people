import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/talent_query.dart';
import '../../domain/failures/scouting_failure.dart';
import '../models/github_talent_model.dart';
import '../models/github_talent_page_model.dart';
import '../models/github_user_search_model.dart';

class GitHubTalentRemoteDataSource {
  const GitHubTalentRemoteDataSource({
    required this.client,
    required this.apiBaseUrl,
    this.requestTimeout = const Duration(seconds: 15),
    this.searchTimeout = const Duration(seconds: 30),
  });

  static const int pageSize = 12;

  final http.Client client;
  final String apiBaseUrl;
  final Duration requestTimeout;
  final Duration searchTimeout;

  Future<GitHubTalentPageModel> search(
    TalentQuery query, {
    required String accessToken,
    required int page,
  }) {
    if (page < 1) {
      throw const ScoutingFailure(ScoutingFailureReason.invalidResponse);
    }
    return _search(query, accessToken: accessToken, page: page).timeout(
      searchTimeout,
      onTimeout: () =>
          throw const ScoutingFailure(ScoutingFailureReason.requestTimedOut),
    );
  }

  Future<GitHubTalentPageModel> _search(
    TalentQuery query, {
    required String accessToken,
    required int page,
  }) async {
    final searchUri = _apiUri('search/users').replace(
      queryParameters: <String, String>{
        'q': query.toGitHubQuery(),
        'per_page': '$pageSize',
        'page': '$page',
      },
    );
    final response = await _get(searchUri, accessToken);
    _validateResponse(response);

    late final GitHubUserSearchModel searchResults;
    try {
      searchResults = GitHubUserSearchModel.fromJson(response.body);
    } on FormatException {
      throw const ScoutingFailure(ScoutingFailureReason.invalidResponse);
    }

    final talents = await Future.wait(
      searchResults.logins.map((login) => _loadTalent(login, accessToken)),
    );
    return GitHubTalentPageModel(
      talents: talents,
      totalCount: searchResults.totalCount,
    );
  }

  Future<GitHubTalentModel> _loadTalent(
    String login,
    String accessToken,
  ) async {
    final encodedLogin = Uri.encodeComponent(login);
    final responses = await Future.wait(<Future<http.Response>>[
      _get(_apiUri('users/$encodedLogin'), accessToken),
      _get(
        _apiUri('users/$encodedLogin/repos').replace(
          queryParameters: const <String, String>{
            'per_page': '100',
            'sort': 'updated',
          },
        ),
        accessToken,
      ),
    ]);
    final profileResponse = responses[0];
    final repositoriesResponse = responses[1];
    _validateResponse(profileResponse);
    _validateResponse(repositoriesResponse);

    try {
      return GitHubTalentModel.fromJson(
        profileResponse.body,
        repositoriesResponse.body,
      );
    } on FormatException {
      throw const ScoutingFailure(ScoutingFailureReason.invalidResponse);
    }
  }

  Uri _apiUri(String path) {
    final baseUri = Uri.parse(
      apiBaseUrl.endsWith('/') ? apiBaseUrl : '$apiBaseUrl/',
    );
    return baseUri.resolve(path);
  }

  Map<String, String> _headers(String accessToken) => <String, String>{
    HttpHeaders.acceptHeader: 'application/vnd.github+json',
    HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  Future<http.Response> _get(Uri uri, String accessToken) async {
    try {
      return await client
          .get(uri, headers: _headers(accessToken))
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const ScoutingFailure(ScoutingFailureReason.requestTimedOut);
    }
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode == HttpStatus.unauthorized) {
      throw const ScoutingFailure(ScoutingFailureReason.authenticationRequired);
    }
    final responseMessage = response.body.toLowerCase();
    if (response.statusCode == HttpStatus.tooManyRequests ||
        (response.statusCode == HttpStatus.forbidden &&
            (response.headers['x-ratelimit-remaining'] == '0' ||
                responseMessage.contains('rate limit') ||
                responseMessage.contains('abuse detection')))) {
      throw const ScoutingFailure(ScoutingFailureReason.rateLimitExceeded);
    }
    if (response.statusCode != HttpStatus.ok) {
      throw const ScoutingFailure(ScoutingFailureReason.service);
    }
  }
}
