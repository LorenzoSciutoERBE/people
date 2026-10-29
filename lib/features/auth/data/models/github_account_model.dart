import 'dart:convert';

import '../../domain/entities/auth_session.dart';

class GitHubAccountModel {
  const GitHubAccountModel({
    required this.login,
    required this.profileUrl,
    this.name,
    this.avatarUrl,
  });

  final String login;
  final String profileUrl;
  final String? name;
  final String? avatarUrl;

  factory GitHubAccountModel.fromJson(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'GitHub user response must be a JSON object.',
      );
    }

    final login = decoded['login'];
    final profileUrl = decoded['html_url'];
    final name = decoded['name'];
    final avatarUrl = decoded['avatar_url'];
    if (login is! String ||
        login.isEmpty ||
        profileUrl is! String ||
        profileUrl.isEmpty ||
        (name != null && name is! String) ||
        (avatarUrl != null && avatarUrl is! String)) {
      throw const FormatException('GitHub user response has invalid fields.');
    }

    return GitHubAccountModel(
      login: login,
      profileUrl: profileUrl,
      name: name as String?,
      avatarUrl: avatarUrl as String?,
    );
  }

  AuthSession toEntity(String accessToken) => AuthSession(
    username: login,
    accessToken: accessToken,
    profileUrl: profileUrl,
    displayName: name,
    avatarUrl: avatarUrl,
  );
}
