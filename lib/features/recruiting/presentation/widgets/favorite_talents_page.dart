import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../candidate_management/domain/entities/recruiting_data.dart';
import '../../../candidate_management/presentation/providers/candidate_management_providers.dart';

class FavoriteTalentsPage extends ConsumerWidget {
  const FavoriteTalentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final state = ref.watch(candidateManagementControllerProvider);
    return state.when(
      data: (data) {
        if (data.favorites.isEmpty) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_border,
                    size: 54,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localization.recruitingFavoritesTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localization.recruitingFavoritesEmpty,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                localization.recruitingFavoritesTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 420,
                  mainAxisExtent: 280,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: data.favorites.length,
                itemBuilder: (context, index) => _FavoriteTalentCard(
                  favorite: data.favorites[index],
                  candidateExists: data.candidates.any(
                    (candidate) =>
                        candidate.githubUrl == data.favorites[index].profileUrl,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      error: (error, stackTrace) =>
          Center(child: Text(localization.candidateActionFailed)),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _FavoriteTalentCard extends ConsumerWidget {
  const _FavoriteTalentCard({
    required this.favorite,
    required this.candidateExists,
  });

  final FavoriteTalent favorite;
  final bool candidateExists;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: favorite.avatarUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person_outline),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.displayName.isEmpty
                            ? favorite.username
                            : favorite.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '@${favorite.username}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: localization.recruitingRemoveFavorite,
                  onPressed: () => _remove(context, ref),
                  icon: const Icon(Icons.star),
                ),
              ],
            ),
            if (favorite.location.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                favorite.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                favorite.biography,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (favorite.languages.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: favorite.languages
                    .take(4)
                    .map((language) => Chip(label: Text(language)))
                    .toList(growable: false),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _openProfile(context, localization),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(localization.candidateOpenProfile),
                ),
                const Spacer(),
                if (!candidateExists)
                  FilledButton.tonalIcon(
                    onPressed: () => _addCandidate(context, ref, localization),
                    icon: const Icon(Icons.person_add_alt_1, size: 17),
                    label: Text(localization.recruitingAddFavoriteCandidate),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .deleteFavorite(favorite.id);
    } on Object {
      if (context.mounted) _showError(context);
    }
  }

  Future<void> _addCandidate(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localization,
  ) async {
    final state = ref.read(candidateManagementControllerProvider).asData?.value;
    if (state == null) return;
    final source =
        state.sources
            .where((item) => item.id == 'github' && item.isActive)
            .firstOrNull ??
        state.sources.where((item) => item.isActive).firstOrNull;
    final stage =
        state.stages.where((item) => item.id == 'new').firstOrNull ??
        state.stages
            .where((item) => item.terminalOutcome == TerminalOutcome.active)
            .firstOrNull;
    if (source == null || stage == null) {
      if (context.mounted) _showError(context);
      return;
    }
    final name = favorite.displayName.trim().isEmpty
        ? favorite.username
        : favorite.displayName.trim();
    final parts = name.split(RegExp(r'\s+'));
    final now = DateTime.now().toUtc();
    try {
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .saveCandidate(
            Candidate(
              id: const Uuid().v4(),
              firstName: parts.first,
              lastName: parts.length > 1 ? parts.skip(1).join(' ') : '',
              location: favorite.location,
              headline: favorite.biography,
              skills: favorite.languages,
              githubUrl: favorite.profileUrl,
              sourceId: source.id,
              stageId: stage.id,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } on Object {
      if (context.mounted) _showError(context);
    }
  }

  Future<void> _openProfile(
    BuildContext context,
    AppLocalizations localization,
  ) async {
    try {
      final launched = await launchUrl(
        Uri.parse(favorite.profileUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) _showError(context);
    } on PlatformException {
      if (context.mounted) _showError(context);
    }
  }
}

void _showError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).candidateActionFailed)),
  );
}
