import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/github_talent_remote_data_source.dart';
import '../../domain/entities/talent.dart';
import '../../domain/entities/talent_page.dart';
import '../../domain/entities/talent_query.dart';
import '../../domain/failures/scouting_failure.dart';
import 'scouting_providers.dart';

/// Presentation state of the GitHub search results.
class TalentSearchState {
  const TalentSearchState({
    this.talents = const <Talent>[],
    this.totalCount = 0,
    this.hasSearched = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  /// GitHub only serves the first 1000 results of any search.
  static const int githubResultLimit = 1000;

  final List<Talent> talents;
  final int totalCount;
  final bool hasSearched;
  final bool isLoadingMore;
  final bool loadMoreFailed;

  bool get hasMore =>
      talents.length < totalCount && talents.length < githubResultLimit;

  TalentSearchState copyWith({
    List<Talent>? talents,
    int? totalCount,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) => TalentSearchState(
    talents: talents ?? this.talents,
    totalCount: totalCount ?? this.totalCount,
    hasSearched: hasSearched,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

final talentSearchControllerProvider =
    AsyncNotifierProvider<TalentSearchController, TalentSearchState>(
      TalentSearchController.new,
    );

class TalentSearchController extends AsyncNotifier<TalentSearchState> {
  static const Duration _searchDeadline = Duration(seconds: 35);

  TalentQuery? _query;
  String? _accessToken;
  int _page = 0;
  int _generation = 0;

  @override
  TalentSearchState build() => const TalentSearchState();

  Future<void> search(TalentQuery query, String accessToken) async {
    final generation = ++_generation;
    _query = query;
    _accessToken = accessToken;
    _page = 0;
    state = const AsyncLoading<TalentSearchState>();
    final result = await AsyncValue.guard(() => _fetch(1));
    if (generation != _generation) return;
    state = result.when(
      data: (page) {
        _page = 1;
        return AsyncData<TalentSearchState>(
          TalentSearchState(
            talents: page.talents,
            totalCount: page.totalCount,
            hasSearched: true,
          ),
        );
      },
      error: AsyncError<TalentSearchState>.new,
      loading: () => const AsyncLoading<TalentSearchState>(),
    );
  }

  /// Appends the next page while keeping the loaded results visible.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        current.isLoadingMore ||
        !current.hasMore ||
        _query == null) {
      return;
    }
    final generation = _generation;
    state = AsyncData<TalentSearchState>(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    final result = await AsyncValue.guard(() => _fetch(_page + 1));
    if (generation != _generation) return;
    state = AsyncData<TalentSearchState>(
      result.when(
        data: (page) {
          _page += 1;
          final known = current.talents
              .map((talent) => talent.username)
              .toSet();
          return current.copyWith(
            talents: <Talent>[
              ...current.talents,
              ...page.talents.where(
                (talent) => !known.contains(talent.username),
              ),
            ],
            totalCount: page.totalCount,
            isLoadingMore: false,
          );
        },
        error: (_, _) =>
            current.copyWith(isLoadingMore: false, loadMoreFailed: true),
        loading: () => current.copyWith(isLoadingMore: false),
      ),
    );
  }

  void clear() {
    _generation++;
    _query = null;
    _accessToken = null;
    _page = 0;
    state = const AsyncData<TalentSearchState>(TalentSearchState());
  }

  Future<TalentPage> _fetch(int page) => ref
      .read(searchTalentsUseCaseProvider)
      .call(_query!, accessToken: _accessToken!, page: page)
      .timeout(
        _searchDeadline,
        onTimeout: () =>
            throw const ScoutingFailure(ScoutingFailureReason.requestTimedOut),
      );

  static const int pageSize = GitHubTalentRemoteDataSource.pageSize;
}
