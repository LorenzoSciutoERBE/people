import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:people/app.dart';
import 'package:people/core/l10n/locale_controller.dart';
import 'package:people/features/auth/domain/entities/auth_session.dart';
import 'package:people/features/auth/domain/failures/auth_failure.dart';
import 'package:people/features/auth/presentation/providers/auth_providers.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/repositories/candidate_repository.dart';
import 'package:people/features/candidate_management/di/candidate_management_dependencies.dart';
import 'package:people/features/talent_scouting/data/datasources/github_talent_remote_data_source.dart';
import 'package:people/features/talent_scouting/presentation/providers/scouting_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('switches the UI language from the header menu', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_locale': 'en',
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authNotifierProvider.overrideWith(_TestAuthNotifier.new),
          candidateRepositoryProvider.overrideWith(
            (ref) async => _TestCandidateRepository(),
          ),
        ],
        child: const PeopleApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hiring pipeline'), findsOneWidget);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Candidate sources'), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      isNull,
    );

    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Saved GitHub profiles'), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      3,
    );

    await tester.tap(find.text('GitHub search'));
    await tester.pumpAndSettle();
    expect(find.text('Scouting filters'), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      2,
    );

    await tester.tap(find.text('Candidates'));
    await tester.pumpAndSettle();
    expect(find.text('All candidates'), findsOneWidget);
    expect(find.text('0 of 0 candidates'), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      1,
    );
    await tester.tap(find.byTooltip('Expand or collapse menu'));
    await tester.pumpAndSettle();
    final compactRail = tester.widget<NavigationRail>(
      find.byType(NavigationRail),
    );
    expect(compactRail.extended, isFalse);
    expect(compactRail.selectedIndex, 1);
    expect(find.byIcon(Icons.people), findsOneWidget);
    expect(tester.getSize(find.byType(NavigationRail)).width, 104);

    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Italiano'));
    await tester.pumpAndSettle();

    expect(find.text('Tutti i candidati'), findsOneWidget);
    expect(preferences.getString('app_locale'), 'it');
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets(
    'scouting requires a real filter and exits loading after a search',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      SharedPreferences.setMockInitialValues(<String, Object>{
        'app_locale': 'en',
      });
      final preferences = await SharedPreferences.getInstance();
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
          );
        }
        if (request.url.path == '/users/octocat/repos') {
          return http.Response(
            jsonEncode(<Object?>[
              <String, Object?>{'language': 'Dart'},
            ]),
            200,
          );
        }
        return http.Response('', 404);
      });
      addTearDown(client.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            authNotifierProvider.overrideWith(
              _AuthenticatedTestAuthNotifier.new,
            ),
            candidateRepositoryProvider.overrideWith(
              (ref) async => _TestCandidateRepository(),
            ),
            scoutingHttpClientProvider.overrideWithValue(client),
          ],
          child: const PeopleApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('GitHub search'));
      await tester.pumpAndSettle();

      final startButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start scouting'),
      );
      expect(startButton.onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, 'Flutter');
      await tester.pump();
      final enabledStartButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start scouting'),
      );
      expect(enabledStartButton.onPressed, isNotNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Start scouting'));
      await tester.pumpAndSettle();

      expect(find.text('The Octocat'), findsOneWidget);
      final completedButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Start scouting'),
      );
      expect(completedButton.onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    },
  );

  testWidgets('shows a timeout error instead of remaining in search loading', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_locale': 'en',
    });
    final preferences = await SharedPreferences.getInstance();
    final client = MockClient((_) => Completer<http.Response>().future);
    addTearDown(client.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authNotifierProvider.overrideWith(_AuthenticatedTestAuthNotifier.new),
          candidateRepositoryProvider.overrideWith(
            (ref) async => _TestCandidateRepository(),
          ),
          githubTalentRemoteDataSourceProvider.overrideWithValue(
            GitHubTalentRemoteDataSource(
              client: client,
              apiBaseUrl: 'https://api.github.com',
              requestTimeout: const Duration(milliseconds: 50),
              searchTimeout: const Duration(milliseconds: 100),
            ),
          ),
        ],
        child: const PeopleApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('GitHub search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Flutter');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Start scouting'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'GitHub took too long to respond. Check your connection and retry.',
      ),
      findsOneWidget,
    );
    expect(find.text('Searching GitHub...'), findsNothing);
    expect(tester.takeException(), isNull);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('keeps the connected account panel within a narrow sidebar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_locale': 'en',
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authNotifierProvider.overrideWith(_AuthenticatedTestAuthNotifier.new),
          candidateRepositoryProvider.overrideWith(
            (ref) async => _TestCandidateRepository(),
          ),
        ],
        child: const PeopleApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('GitHub search'));
    await tester.pumpAndSettle();

    expect(find.text('GitHub API connected as: octocat'), findsOneWidget);
    expect(tester.takeException(), isNull);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('shows auth errors without overflowing a narrow sidebar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_locale': 'en',
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authNotifierProvider.overrideWith(_FailedAuthNotifier.new),
          candidateRepositoryProvider.overrideWith(
            (ref) async => _TestCandidateRepository(),
          ),
        ],
        child: const PeopleApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('GitHub search'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'GitHub OAuth credentials are missing from the build configuration.',
      ),
      findsOneWidget,
    );
    expect(find.text('Connect GitHub API'), findsOneWidget);
    expect(tester.takeException(), isNull);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

class _TestAuthNotifier extends AuthNotifier {
  @override
  Future<AuthSession?> build() async => null;
}

class _AuthenticatedTestAuthNotifier extends AuthNotifier {
  @override
  Future<AuthSession?> build() async => const AuthSession(
    username: 'octocat',
    accessToken: 'test-token',
    profileUrl: 'https://github.com/octocat',
  );
}

class _FailedAuthNotifier extends AuthNotifier {
  @override
  Future<AuthSession?> build() async =>
      throw const AuthFailure(AuthFailureReason.missingConfiguration);
}

class _TestCandidateRepository implements CandidateRepository {
  @override
  Future<RecruitingData> load() async => RecruitingData.initial();

  @override
  Future<Candidate> saveCandidate(
    Candidate candidate, {
    List<int>? cvBytes,
  }) async => candidate;

  @override
  Future<void> deleteCandidate(String candidateId) async {}

  @override
  Future<void> saveFavorite(FavoriteTalent favorite) async {}

  @override
  Future<void> deleteFavorite(String favoriteId) async {}

  @override
  Future<void> saveInterviewFeedback(
    String candidateId, {
    required String stageId,
    required FeedbackDecision decision,
    required String notes,
  }) async {}

  @override
  Future<void> moveCandidate(
    String candidateId,
    String destinationStageId,
  ) async {}

  @override
  Future<void> saveOffer(String candidateId, CandidateOffer offer) async {}

  @override
  Future<void> saveConfiguration({
    required List<CandidateSource> sources,
    required List<HiringStage> stages,
  }) async {}

  @override
  Future<List<int>?> readResume(String candidateId) async => null;
}
