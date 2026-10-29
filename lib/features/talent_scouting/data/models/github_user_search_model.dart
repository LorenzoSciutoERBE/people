import 'dart:convert';

class GitHubUserSearchModel {
  const GitHubUserSearchModel({required this.logins, required this.totalCount});

  final List<String> logins;
  final int totalCount;

  factory GitHubUserSearchModel.fromJson(String source) {
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?> ||
        decoded['items'] is! List<Object?>) {
      throw const FormatException('GitHub user search response is invalid.');
    }
    final items = decoded['items']! as List<Object?>;
    final logins = <String>[];
    for (final item in items) {
      if (item is! Map<String, Object?> || item['login'] is! String) {
        throw const FormatException('GitHub user search item is invalid.');
      }
      logins.add(item['login']! as String);
    }
    final totalCount = decoded['total_count'];
    return GitHubUserSearchModel(
      logins: logins,
      totalCount: totalCount is int ? totalCount : logins.length,
    );
  }
}
