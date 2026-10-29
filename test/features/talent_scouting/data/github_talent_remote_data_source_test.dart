import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:people/features/talent_scouting/data/datasources/github_talent_remote_data_source.dart';
import 'package:people/features/talent_scouting/domain/failures/scouting_failure.dart';
import 'package:people/features/talent_scouting/domain/entities/talent_query.dart';

void main() {
  test('searches users, loads public profiles, and maps languages', () async {
    final requestedUris = <Uri>[];
    final client = MockClient((request) async {
      requestedUris.add(request.url);
      if (request.url.path == '/search/users') {
        expect(
          request.url.queryParameters['q'],
          'language:Dart location:"Milan" type:user',
        );
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode(<String, Object?>{
            'items': <Object?>[
              <String, Object?>{'login': 'octocat'},
            ],
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/users/octocat') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'login': 'octocat',
            'html_url': 'https://github.com/octocat',
            'avatar_url': 'https://example.com/octocat.png',
            'public_repos': 42,
            'followers': 100,
            'name': 'The Octocat',
            'location': 'Milan',
            'bio': 'Builds things with Flutter.',
          }),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.url.path == '/users/octocat/repos') {
        return http.Response(
          jsonEncode(<Object?>[
            <String, Object?>{'language': 'Dart'},
            <String, Object?>{'language': 'Dart'},
            <String, Object?>{'language': 'Kotlin'},
          ]),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }
      return http.Response('', 404);
    });
    final dataSource = GitHubTalentRemoteDataSource(
      client: client,
      apiBaseUrl: 'https://api.github.com',
    );

    final page = await dataSource.search(
      const TalentQuery(
        keywords: 'Flutter',
        location: 'Milan',
        minimumRepositories: 0,
        minimumFollowers: 0,
      ),
      accessToken: 'test-token',
      page: 1,
    );

    expect(requestedUris, hasLength(3));
    final candidates = page.talents;
    expect(candidates, hasLength(1));
    expect(candidates.single.username, 'octocat');
    expect(candidates.single.displayName, 'The Octocat');
    expect(candidates.single.location, 'Milan');
    expect(candidates.single.publicRepositoryCount, 42);
    expect(candidates.single.followerCount, 100);
    expect(candidates.single.languages, <String>['Dart', 'Kotlin']);
    client.close();
  });

  test(
    'requests profile enrichment in parallel to avoid sequential delays',
    () async {
      final profileResponse = Completer<http.Response>();
      final repositoriesStarted = Completer<void>();
      final client = MockClient((request) async {
        if (request.url.path == '/search/users') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'items': <Object?>[
                <String, Object?>{'login': 'octocat'},
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/users/octocat') {
          return profileResponse.future;
        }
        if (request.url.path == '/users/octocat/repos') {
          if (!repositoriesStarted.isCompleted) {
            repositoriesStarted.complete();
          }
          return http.Response('[]', 200);
        }
        return http.Response('', 404);
      });
      final dataSource = GitHubTalentRemoteDataSource(
        client: client,
        apiBaseUrl: 'https://api.github.com',
      );
      final search = dataSource.search(
        const TalentQuery(
          keywords: 'Flutter',
          location: '',
          minimumRepositories: 0,
          minimumFollowers: 0,
        ),
        accessToken: 'test-token',
        page: 1,
      );

      var repositoriesStartedBeforeProfile = false;
      try {
        await repositoriesStarted.future.timeout(const Duration(seconds: 1));
        repositoriesStartedBeforeProfile = true;
      } on TimeoutException {
        repositoriesStartedBeforeProfile = false;
      }
      profileResponse.complete(
        http.Response(
          jsonEncode(<String, Object?>{
            'login': 'octocat',
            'html_url': 'https://github.com/octocat',
            'avatar_url': 'https://example.com/octocat.png',
            'public_repos': 1,
            'followers': 1,
          }),
          200,
        ),
      );
      await search;

      expect(repositoriesStartedBeforeProfile, isTrue);
      client.close();
    },
  );

  test(
    'fails with a typed timeout instead of staying in loading state',
    () async {
      final pendingResponse = Completer<http.Response>();
      final client = MockClient((request) => pendingResponse.future);
      final dataSource = GitHubTalentRemoteDataSource(
        client: client,
        apiBaseUrl: 'https://api.github.com',
        requestTimeout: const Duration(milliseconds: 10),
      );

      await expectLater(
        dataSource.search(
          const TalentQuery(
            keywords: 'Flutter',
            location: '',
            minimumRepositories: 0,
            minimumFollowers: 0,
          ),
          accessToken: 'test-token',
          page: 1,
        ),
        throwsA(
          isA<ScoutingFailure>().having(
            (failure) => failure.reason,
            'reason',
            ScoutingFailureReason.requestTimedOut,
          ),
        ),
      );
      client.close();
    },
  );

  test(
    'maps GitHub secondary rate limits to a retryable scouting failure',
    () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object?>{
            'message': 'You have exceeded a secondary rate limit.',
          }),
          403,
          headers: const <String, String>{'x-ratelimit-remaining': '4999'},
        ),
      );
      final dataSource = GitHubTalentRemoteDataSource(
        client: client,
        apiBaseUrl: 'https://api.github.com',
      );

      await expectLater(
        dataSource.search(
          const TalentQuery(
            keywords: 'Flutter',
            location: '',
            minimumRepositories: 0,
            minimumFollowers: 0,
          ),
          accessToken: 'test-token',
          page: 1,
        ),
        throwsA(
          isA<ScoutingFailure>().having(
            (failure) => failure.reason,
            'reason',
            ScoutingFailureReason.rateLimitExceeded,
          ),
        ),
      );
      client.close();
    },
  );
}
