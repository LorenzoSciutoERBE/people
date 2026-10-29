import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/failures/auth_failure.dart';
import '../models/github_account_model.dart';

class GitHubAccountRemoteDataSource {
  static const Duration requestTimeout = Duration(seconds: 15);

  const GitHubAccountRemoteDataSource({
    required this.client,
    required this.apiBaseUrl,
  });

  final http.Client client;
  final String apiBaseUrl;

  Future<GitHubAccountModel> getCurrentAccount(String accessToken) async {
    final baseUri = Uri.parse(
      apiBaseUrl.endsWith('/') ? apiBaseUrl : '$apiBaseUrl/',
    );
    late final http.Response response;
    try {
      response = await client
          .get(
            baseUri.resolve('user'),
            headers: <String, String>{
              HttpHeaders.acceptHeader: 'application/vnd.github+json',
              HttpHeaders.authorizationHeader: 'Bearer $accessToken',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const AuthFailure(AuthFailureReason.network);
    }
    if (response.statusCode == HttpStatus.unauthorized) {
      throw const AuthFailure(AuthFailureReason.invalidCredentials);
    }
    if (response.statusCode != HttpStatus.ok) {
      throw const AuthFailure(AuthFailureReason.service);
    }

    try {
      return GitHubAccountModel.fromJson(response.body);
    } on FormatException {
      throw const AuthFailure(AuthFailureReason.service);
    }
  }
}
