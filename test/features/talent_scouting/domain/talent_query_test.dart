import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/talent_scouting/domain/entities/talent_query.dart';

void main() {
  test('builds GitHub user search qualifiers from scouting filters', () {
    const query = TalentQuery(
      keywords: '  Flutter  ',
      location: 'Milan, Italy',
      minimumRepositories: 8,
      minimumFollowers: 25,
    );

    expect(
      query.toGitHubQuery(),
      'language:Dart location:"Milan, Italy" repos:>=8 followers:>=25 type:user',
    );
  });

  test('maps a programming language and omits blank optional filters', () {
    const query = TalentQuery(
      keywords: 'Rust',
      location: ' ',
      minimumRepositories: 0,
      minimumFollowers: 0,
    );

    expect(query.toGitHubQuery(), 'language:Rust type:user');
  });

  test('keeps free-form search terms', () {
    const query = TalentQuery(
      keywords: 'machine learning',
      location: '',
      minimumRepositories: 0,
      minimumFollowers: 0,
    );

    expect(query.toGitHubQuery(), 'machine learning type:user');
  });

  test('returns no query when every scouting filter is empty', () {
    const query = TalentQuery(
      keywords: '  ',
      location: '',
      minimumRepositories: 0,
      minimumFollowers: 0,
    );

    expect(query.toGitHubQuery(), isEmpty);
  });

  test(
    'allows reputation-only filters without searching every GitHub user',
    () {
      const query = TalentQuery(
        keywords: '',
        location: '',
        minimumRepositories: 10,
        minimumFollowers: 25,
      );

      expect(query.toGitHubQuery(), 'repos:>=10 followers:>=25 type:user');
    },
  );
}
