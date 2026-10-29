import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/auth/data/models/github_account_model.dart';

void main() {
  test('maps a valid GitHub account response', () {
    final account = GitHubAccountModel.fromJson(
      '{"login":"octocat","html_url":"https://github.com/octocat",'
      '"name":"The Octocat","avatar_url":"https://example.com/avatar.png"}',
    );

    final session = account.toEntity('token-value');

    expect(session.username, 'octocat');
    expect(session.displayName, 'The Octocat');
    expect(session.profileUrl, 'https://github.com/octocat');
    expect(session.accessToken, 'token-value');
  });

  test('rejects a malformed GitHub account response', () {
    expect(
      () => GitHubAccountModel.fromJson('{"login":42}'),
      throwsFormatException,
    );
  });
}
