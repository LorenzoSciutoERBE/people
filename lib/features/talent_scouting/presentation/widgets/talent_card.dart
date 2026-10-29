import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../candidate_management/domain/entities/recruiting_data.dart';
import '../../../candidate_management/presentation/providers/candidate_management_providers.dart';
import '../../domain/entities/talent.dart';
import 'language_badge.dart';

class TalentCard extends ConsumerWidget {
  const TalentCard({super.key, required this.talent});

  final Talent talent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final displayName = talent.displayName?.trim();
    final recruitingState = ref.watch(candidateManagementControllerProvider);
    final favorite = recruitingState.asData?.value.favorites
        .where((item) => item.id == talent.username.toLowerCase())
        .firstOrNull;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: talent.avatarUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Icon(Icons.person_outline, size: 28),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person_outline, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName == null || displayName.isEmpty
                            ? talent.username
                            : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '@${talent.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (talent.location case final location? when location.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                talent.biography?.trim().isNotEmpty == true
                    ? talent.biography!.trim()
                    : localization.scoutingNoBiography,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.folder_outlined, size: 16),
                const SizedBox(width: 4),
                Text(count.format(talent.publicRepositoryCount)),
                const SizedBox(width: 12),
                const Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 4),
                Text(count.format(talent.followerCount)),
                const Spacer(),
                Text(
                  localization.scoutingPublicActivity,
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            if (talent.languages.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 0,
                children: talent.languages
                    .map((language) => LanguageBadge(language: language))
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: favorite == null
                        ? localization.recruitingSaveFavorite
                        : localization.recruitingRemoveFavorite,
                    onPressed: recruitingState.hasValue
                        ? () => _toggleFavorite(
                            context,
                            ref,
                            localization,
                            favorite,
                          )
                        : null,
                    icon: Icon(
                      favorite == null ? Icons.star_outline : Icons.star,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    tooltip: localization.candidateAddFromScouting,
                    onPressed: recruitingState.hasValue
                        ? () => _addToHiringBoard(context, ref, localization)
                        : null,
                    icon: const Icon(Icons.playlist_add, size: 20),
                  ),
                  TextButton.icon(
                    onPressed: () => _openProfile(context, localization),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(localization.scoutingOpenProfile),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProfile(
    BuildContext context,
    AppLocalizations localization,
  ) async {
    try {
      final opened = await launchUrl(
        Uri.parse(talent.profileUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.scoutingOpenProfileError)),
        );
      }
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.scoutingOpenProfileError)),
        );
      }
    }
  }

  Future<void> _addToHiringBoard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localization,
  ) async {
    try {
      final data = ref
          .read(candidateManagementControllerProvider)
          .asData
          ?.value;
      if (data == null) return;
      if (data.candidates.any(
        (candidate) => candidate.githubUrl == talent.profileUrl,
      )) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localization.candidateAlreadyTracked)),
          );
        }
        return;
      }
      final activeSources = data.sources
          .where((source) => source.isActive)
          .toList(growable: false);
      if (activeSources.isEmpty || data.stages.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localization.candidateActionFailed)),
          );
        }
        return;
      }
      final source =
          activeSources
              .where((candidateSource) => candidateSource.id == 'github')
              .firstOrNull ??
          activeSources.first;
      final displayName = talent.displayName?.trim();
      final nameParts =
          (displayName == null || displayName.isEmpty
                  ? talent.username
                  : displayName)
              .split(RegExp(r'\s+'));
      final now = DateTime.now().toUtc();
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .saveCandidate(
            Candidate(
              id: const Uuid().v4(),
              firstName: nameParts.first,
              lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
              location: talent.location ?? '',
              headline: talent.biography ?? '',
              skills: talent.languages,
              githubUrl: talent.profileUrl,
              sourceId: source.id,
              stageId:
                  data.stages
                      .where((stage) => stage.id == 'new')
                      .firstOrNull
                      ?.id ??
                  data.stages.first.id,
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.candidateAddFromScouting)),
        );
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.candidateActionFailed)),
        );
      }
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localization,
    FavoriteTalent? existing,
  ) async {
    try {
      final controller = ref.read(
        candidateManagementControllerProvider.notifier,
      );
      if (existing != null) {
        await controller.deleteFavorite(existing.id);
      } else {
        await controller.saveFavorite(
          FavoriteTalent(
            id: talent.username.toLowerCase(),
            username: talent.username,
            profileUrl: talent.profileUrl,
            avatarUrl: talent.avatarUrl,
            displayName: talent.displayName ?? '',
            location: talent.location ?? '',
            biography: talent.biography ?? '',
            languages: talent.languages,
            savedAt: DateTime.now().toUtc(),
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localization.recruitingFavoriteSaved)),
          );
        }
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.candidateActionFailed)),
        );
      }
    }
  }
}
