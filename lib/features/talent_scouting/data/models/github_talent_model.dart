import 'dart:convert';

import '../../domain/entities/talent.dart';

class GitHubTalentModel {
  const GitHubTalentModel({
    required this.username,
    required this.profileUrl,
    required this.avatarUrl,
    required this.publicRepositoryCount,
    required this.followerCount,
    required this.languages,
    this.displayName,
    this.location,
    this.biography,
  });

  final String username;
  final String profileUrl;
  final String avatarUrl;
  final String? displayName;
  final String? location;
  final String? biography;
  final int publicRepositoryCount;
  final int followerCount;
  final List<String> languages;

  factory GitHubTalentModel.fromJson(String userJson, String repositoriesJson) {
    final Object? userDecoded = jsonDecode(userJson);
    final Object? repositoriesDecoded = jsonDecode(repositoriesJson);
    if (userDecoded is! Map<String, Object?> ||
        repositoriesDecoded is! List<Object?>) {
      throw const FormatException('GitHub profile response is invalid.');
    }

    final login = userDecoded['login'];
    final profileUrl = userDecoded['html_url'];
    final avatarUrl = userDecoded['avatar_url'];
    final publicRepos = userDecoded['public_repos'];
    final followers = userDecoded['followers'];
    final name = userDecoded['name'];
    final location = userDecoded['location'];
    final biography = userDecoded['bio'];
    if (login is! String ||
        profileUrl is! String ||
        avatarUrl is! String ||
        publicRepos is! int ||
        followers is! int ||
        !_optionalString(name) ||
        !_optionalString(location) ||
        !_optionalString(biography)) {
      throw const FormatException('GitHub profile fields are invalid.');
    }

    final languageCounts = <String, int>{};
    for (final repository in repositoriesDecoded) {
      if (repository is! Map<String, Object?>) {
        throw const FormatException('GitHub repository response is invalid.');
      }
      final language = repository['language'];
      if (language is String && language.isNotEmpty) {
        languageCounts.update(
          language,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      } else if (language != null) {
        throw const FormatException('GitHub repository language is invalid.');
      }
    }
    final languages = languageCounts.keys.toList()
      ..sort(
        (first, second) =>
            languageCounts[second]!.compareTo(languageCounts[first]!),
      );

    return GitHubTalentModel(
      username: login,
      profileUrl: profileUrl,
      avatarUrl: avatarUrl,
      publicRepositoryCount: publicRepos,
      followerCount: followers,
      languages: languages.take(5).toList(growable: false),
      displayName: name as String?,
      location: location as String?,
      biography: biography as String?,
    );
  }

  Talent toEntity() => Talent(
    username: username,
    profileUrl: profileUrl,
    avatarUrl: avatarUrl,
    publicRepositoryCount: publicRepositoryCount,
    followerCount: followerCount,
    languages: languages,
    displayName: displayName,
    location: location,
    biography: biography,
  );

  static bool _optionalString(Object? value) =>
      value == null || value is String;
}
