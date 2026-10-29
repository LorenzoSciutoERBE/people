import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/failures/scouting_failure.dart';
import '../providers/scouting_providers.dart';
import '../providers/talent_search_controller.dart';
import 'results_skeleton.dart';
import 'talent_card.dart';

class ResultsArea extends ConsumerWidget {
  const ResultsArea({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    return authState.when(
      data: (session) => session == null
          ? _Message(
              icon: Icons.link,
              message: localization.scoutingConnectFirst,
            )
          : _buildResults(context, ref, localization),
      error: (error, stackTrace) => _Message(
        icon: Icons.error_outline,
        message: localization.scoutingAuthenticationRequired,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildResults(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localization,
  ) {
    final searchState = ref.watch(talentSearchControllerProvider);
    return searchState.when(
      data: (search) {
        if (search.talents.isEmpty) {
          return _Message(
            icon: Icons.search,
            message: search.hasSearched
                ? localization.scoutingNoResults
                : localization.scoutingReadyPrompt,
          );
        }
        return _TalentResults(search: search);
      },
      error: (error, stackTrace) => _ErrorMessage(
        message: _failureMessage(localization, error),
        onRetry: () {
          final filters = ref.read(scoutingFiltersProvider);
          final session = ref.read(authNotifierProvider).asData?.value;
          if (session != null) {
            ref
                .read(talentSearchControllerProvider.notifier)
                .search(filters.toQuery(), session.accessToken);
          }
        },
      ),
      loading: () => const ResultsSkeleton(),
    );
  }

  String _failureMessage(AppLocalizations localization, Object error) {
    if (error is! ScoutingFailure) return localization.scoutingServiceError;
    return switch (error.reason) {
      ScoutingFailureReason.emptyQuery => localization.scoutingEmptyQuery,
      ScoutingFailureReason.authenticationRequired =>
        localization.scoutingAuthenticationRequired,
      ScoutingFailureReason.rateLimitExceeded =>
        localization.scoutingRateLimitExceeded,
      ScoutingFailureReason.requestTimedOut =>
        localization.scoutingRequestTimedOut,
      ScoutingFailureReason.invalidResponse =>
        localization.scoutingInvalidResponse,
      ScoutingFailureReason.network => localization.scoutingNetworkError,
      ScoutingFailureReason.service => localization.scoutingServiceError,
    };
  }
}

class _TalentResults extends ConsumerWidget {
  const _TalentResults({required this.search});

  final TalentSearchState search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final searchController = ref.read(talentSearchControllerProvider.notifier);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              Text(
                localization.scoutingResultsOfTotal(
                  search.talents.length,
                  search.totalCount,
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 390,
                    mainAxisExtent: 310,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: search.talents.length,
                  itemBuilder: (context, index) =>
                      TalentCard(talent: search.talents[index]),
                ),
              ),
              if (search.hasMore || search.loadMoreFailed)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      children: [
                        if (search.loadMoreFailed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              localization.scoutingLoadMoreFailed,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        FilledButton.tonalIcon(
                          onPressed: search.isLoadingMore
                              ? null
                              : searchController.loadMore,
                          icon: search.isLoadingMore
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(localization.scoutingLoadMore),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(localization.scoutingRetry),
          ),
        ],
      ),
    );
  }
}
