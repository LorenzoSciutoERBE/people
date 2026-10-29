import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../data/datasources/github_talent_remote_data_source.dart';
import '../../data/repositories/github_talent_repository.dart';
import '../../domain/entities/talent_query.dart';
import '../../domain/repositories/talent_repository.dart';
import '../../domain/usecases/search_talents_use_case.dart';

class ScoutingFilters {
  const ScoutingFilters({
    this.keywords = '',
    this.location = '',
    this.minimumRepositories = 0,
    this.minimumFollowers = 0,
  });

  final String keywords;
  final String location;
  final int minimumRepositories;
  final int minimumFollowers;

  TalentQuery toQuery() => TalentQuery(
    keywords: keywords,
    location: location,
    minimumRepositories: minimumRepositories,
    minimumFollowers: minimumFollowers,
  );

  ScoutingFilters copyWith({
    String? keywords,
    String? location,
    int? minimumRepositories,
    int? minimumFollowers,
  }) => ScoutingFilters(
    keywords: keywords ?? this.keywords,
    location: location ?? this.location,
    minimumRepositories: minimumRepositories ?? this.minimumRepositories,
    minimumFollowers: minimumFollowers ?? this.minimumFollowers,
  );
}

class ScoutingFiltersNotifier extends Notifier<ScoutingFilters> {
  @override
  ScoutingFilters build() => const ScoutingFilters();

  void updateKeywords(String value) {
    state = state.copyWith(keywords: value);
  }

  void updateLocation(String value) {
    state = state.copyWith(location: value);
  }

  void updateMinimumRepositories(int value) {
    state = state.copyWith(minimumRepositories: value);
  }

  void updateMinimumFollowers(int value) {
    state = state.copyWith(minimumFollowers: value);
  }

  void reset() {
    state = const ScoutingFilters();
  }
}

final scoutingFiltersProvider =
    NotifierProvider<ScoutingFiltersNotifier, ScoutingFilters>(
      ScoutingFiltersNotifier.new,
    );

final scoutingHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final githubTalentRemoteDataSourceProvider =
    Provider<GitHubTalentRemoteDataSource>(
      (ref) => GitHubTalentRemoteDataSource(
        client: ref.watch(scoutingHttpClientProvider),
        apiBaseUrl: AppConfig.githubApiBaseUrl,
      ),
    );

final talentRepositoryProvider = Provider<TalentRepository>(
  (ref) =>
      GitHubTalentRepository(ref.watch(githubTalentRemoteDataSourceProvider)),
);

final searchTalentsUseCaseProvider = Provider<SearchTalentsUseCase>(
  (ref) => SearchTalentsUseCase(ref.watch(talentRepositoryProvider)),
);
