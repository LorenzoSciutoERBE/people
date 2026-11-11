import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../candidate_management/domain/entities/recruiting_data.dart';
import '../../../candidate_management/presentation/providers/candidate_management_providers.dart';
import '../../../candidate_management/presentation/widgets/candidate_dialog_support.dart';
import '../../domain/entities/talent.dart';
import 'language_badge.dart';

class TalentCard extends ConsumerWidget {
  TalentCard({super.key, required Talent talent})
    : username = talent.username,
      profileUrl = talent.profileUrl,
      avatarUrl = talent.avatarUrl,
      displayName = talent.displayName,
      location = talent.location,
      biography = talent.biography,
      publicRepositoryCount = talent.publicRepositoryCount,
      followerCount = talent.followerCount,
      languages = talent.languages;

  TalentCard.favorite({super.key, required FavoriteTalent favorite})
    : username = favorite.username,
      profileUrl = favorite.profileUrl,
      avatarUrl = favorite.avatarUrl,
      displayName = favorite.displayName,
      location = favorite.location,
      biography = favorite.biography,
      publicRepositoryCount = null,
      followerCount = null,
      languages = favorite.languages;

  final String username;
  final String profileUrl;
  final String avatarUrl;
  final String? displayName;
  final String? location;
  final String? biography;
  final int? publicRepositoryCount;
  final int? followerCount;
  final List<String> languages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final trimmedName = displayName?.trim();
    final recruitingState = ref.watch(candidateManagementControllerProvider);
    final recruitingData = recruitingState.asData?.value;
    final favorite = recruitingData?.favorites
        .where((item) => item.id == username.toLowerCase())
        .firstOrNull;
    final candidateExists =
        recruitingData?.candidates.any(
          (candidate) => candidate.githubUrl == profileUrl,
        ) ??
        false;
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
                      imageUrl: avatarUrl,
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
                        trimmedName == null || trimmedName.isEmpty
                            ? username
                            : trimmedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '@$username',
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
            if (location case final loc? when loc.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      loc,
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
                biography?.trim().isNotEmpty == true
                    ? biography!.trim()
                    : localization.scoutingNoBiography,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (publicRepositoryCount != null && followerCount != null)
              Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(count.format(publicRepositoryCount)),
                  const SizedBox(width: 12),
                  const Icon(Icons.people_outline, size: 16),
                  const SizedBox(width: 4),
                  Text(count.format(followerCount)),
                  const Spacer(),
                  Text(
                    localization.scoutingPublicActivity,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            if (languages.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 0,
                children: languages
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
                      color: favorite == null ? null : Colors.amber.shade700,
                    ),
                  ),
                  IconButton(
                    tooltip: candidateExists
                        ? localization.candidateAlreadyTracked
                        : localization.candidateAddFromScouting,
                    onPressed: recruitingState.hasValue
                        ? () => _addToHiringBoard(context, ref, localization)
                        : null,
                    icon: Icon(
                      candidateExists
                          ? Icons.playlist_add_check
                          : Icons.playlist_add,
                      size: 20,
                      color: candidateExists ? const Color(0xFF1E8E3E) : null,
                    ),
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
        Uri.parse(profileUrl),
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
        (candidate) => candidate.githubUrl == profileUrl,
      )) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(localization.candidateAlreadyTracked)),
          );
        }
        return;
      }
      final candidate = createCandidateFromGithubProfile(
        data: data,
        username: username,
        profileUrl: profileUrl,
        displayName: displayName,
        location: location,
        biography: biography,
        languages: languages,
      );
      if (candidate == null) {
        if (context.mounted) showCandidateActionError(context);
        return;
      }
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .saveCandidate(candidate);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.candidateAddFromScouting)),
        );
      }
    } on Object {
      if (context.mounted) showCandidateActionError(context);
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
            id: username.toLowerCase(),
            username: username,
            profileUrl: profileUrl,
            avatarUrl: avatarUrl,
            displayName: displayName ?? '',
            location: location ?? '',
            biography: biography ?? '',
            languages: languages,
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
