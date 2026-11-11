import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/language_menu.dart';
import '../../../../shared/widgets/window_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../candidate_management/presentation/providers/candidate_management_providers.dart';
import '../../../candidate_management/presentation/widgets/candidate_board.dart';
import '../../../candidate_management/presentation/widgets/candidates_page.dart';
import '../../../candidate_management/presentation/widgets/recruiting_settings.dart';
import '../../../candidate_management/presentation/widgets/hired_people_page.dart';
import '../../../candidate_management/presentation/widgets/employment_reminders_banner.dart';
import '../../../talent_scouting/presentation/pages/scouting_workspace.dart';
import '../../../talent_scouting/presentation/providers/talent_search_controller.dart';
import '../widgets/favorite_talents_page.dart';

enum RecruitingDestination {
  pipeline,
  candidates,
  search,
  favorites,
  hiredPeople,
  settings,
}

/// Application shell: top window bar, side navigation and the active page.
class RecruitingShellPage extends ConsumerStatefulWidget {
  const RecruitingShellPage({
    super.key,
    this.initialDestination = RecruitingDestination.pipeline,
  });

  final RecruitingDestination initialDestination;

  @override
  ConsumerState<RecruitingShellPage> createState() =>
      _RecruitingShellPageState();
}

class _RecruitingShellPageState extends ConsumerState<RecruitingShellPage> {
  static const List<RecruitingDestination> _navigationItems =
      <RecruitingDestination>[
        RecruitingDestination.pipeline,
        RecruitingDestination.candidates,
        RecruitingDestination.search,
        RecruitingDestination.favorites,
        RecruitingDestination.hiredPeople,
      ];

  late RecruitingDestination _destination = widget.initialDestination;

  bool _navigationExpanded = true;

  void _select(RecruitingDestination destination) =>
      setState(() => _destination = destination);

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.asData?.value == null) {
        ref.read(talentSearchControllerProvider.notifier).clear();
      }
    });
    final localization = AppLocalizations.of(context);
    return _buildScaffold(localization);
  }

  Widget _buildScaffold(AppLocalizations localization) {
    final settingsOpen = _destination == RecruitingDestination.settings;
    final evaluationsVisible = ref.watch(evaluationsVisibleProvider);
    return Scaffold(
      appBar: WindowHeader(
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('toggle-evaluations-visibility'),
              tooltip: evaluationsVisible
                  ? localization.recruitingHideEvaluations
                  : localization.recruitingShowEvaluations,
              isSelected: !evaluationsVisible,
              onPressed: () =>
                  ref.read(evaluationsVisibleProvider.notifier).toggle(),
              icon: Icon(
                evaluationsVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
            const LanguageMenu(),
          ],
        ),
      ),
      body: Row(
        children: [
          _SideNavigation(
            expanded:
                _navigationExpanded && MediaQuery.sizeOf(context).width >= 1100,
            settingsOpen: settingsOpen,
            onToggle: () =>
                setState(() => _navigationExpanded = !_navigationExpanded),
            selectedIndex: settingsOpen
                ? null
                : _navigationItems.indexOf(_destination),
            onSelected: (index) => _select(_navigationItems[index]),
            onSelectSettings: () => _select(RecruitingDestination.settings),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              children: [
                EmploymentRemindersBanner(
                  onOpen: () => _select(RecruitingDestination.hiredPeople),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.01, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_destination),
                      child: _buildDestination(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestination() => switch (_destination) {
    RecruitingDestination.pipeline => const CandidateBoard(),
    RecruitingDestination.candidates => const CandidatesPage(),
    RecruitingDestination.search => const ScoutingWorkspace(),
    RecruitingDestination.favorites => const FavoriteTalentsPage(),
    RecruitingDestination.hiredPeople => const HiredPeoplePage(),
    RecruitingDestination.settings => const RecruitingSettings(),
  };
}

class _SideNavigation extends ConsumerWidget {
  const _SideNavigation({
    required this.expanded,
    required this.settingsOpen,
    required this.selectedIndex,
    required this.onSelected,
    required this.onSelectSettings,
    required this.onToggle,
  });

  final VoidCallback onToggle;
  final VoidCallback onSelectSettings;
  final bool expanded;
  final bool settingsOpen;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  Widget _navIcon(Widget icon, {required int count, required String? tooltip}) {
    final badged = count > 0 ? Badge(label: Text('$count'), child: icon) : icon;
    if (tooltip == null || tooltip.isEmpty) return badged;
    return Tooltip(message: tooltip, child: badged);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final data = ref.watch(candidateManagementControllerProvider).asData?.value;
    final candidateCount = data?.candidates.length ?? 0;
    final favoriteCount = data?.favorites.length ?? 0;
    return Material(
      color: Colors.white,
      child: AnimatedContainer(
        duration: kThemeAnimationDuration,
        curve: Curves.easeOutCubic,
        width: expanded ? 248 : 104,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: expanded
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (expanded)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          localization.recruitingNavSection.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: localization.recruitingNavToggle,
                    onPressed: onToggle,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF4F7FB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      expanded
                          ? Icons.keyboard_double_arrow_left_rounded
                          : Icons.menu_rounded,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        extended: expanded,
                        minWidth: 56,
                        minExtendedWidth: 248,
                        groupAlignment: -1,
                        backgroundColor: Colors.white,
                        selectedIndex: selectedIndex,
                        labelType: NavigationRailLabelType.none,
                        onDestinationSelected: onSelected,
                        destinations: [
                          NavigationRailDestination(
                            icon: _navIcon(
                              const Icon(Icons.view_kanban_outlined),
                              count: 0,
                              tooltip: expanded
                                  ? null
                                  : localization.recruitingNavPipeline,
                            ),
                            selectedIcon: _navIcon(
                              const Icon(Icons.view_kanban),
                              count: 0,
                              tooltip: expanded
                                  ? null
                                  : localization.recruitingNavPipeline,
                            ),
                            label: Text(localization.recruitingNavPipeline),
                          ),
                          NavigationRailDestination(
                            icon: _navIcon(
                              const Icon(Icons.people_outline),
                              count: candidateCount,
                              tooltip: expanded
                                  ? null
                                  : localization.recruitingNavCandidates,
                            ),
                            selectedIcon: _navIcon(
                              const Icon(Icons.people),
                              count: candidateCount,
                              tooltip: expanded
                                  ? null
                                  : localization.recruitingNavCandidates,
                            ),
                            label: Text(localization.recruitingNavCandidates),
                          ),
                          NavigationRailDestination(
                            icon: _navIcon(
                              const Icon(
                                Icons.manage_search_outlined,
                                key: Key('navigation-search'),
                              ),
                              count: 0,
                              tooltip: expanded
                                  ? null
                                  : localization.recruitingNavSearch,
                            ),
                            selectedIcon: _navIcon(
                              const Icon(Icons.manage_search),
                              count: 0,
                              tooltip: expanded
                                  ? null
                                  : localization.recruitingNavSearch,
                            ),
                            label: Text(localization.recruitingNavSearch),
                          ),
                          NavigationRailDestination(
                            icon: _navIcon(
                              const Icon(Icons.star_outline),
                              count: favoriteCount,
                              tooltip: expanded
                                  ? null
                                  : localization.recruitingNavFavorites,
                            ),
                            selectedIcon: _navIcon(
                              const Icon(Icons.star),
                              count: favoriteCount,
                              tooltip: expanded
                                  ? null
                                  : localization.recruitingNavFavorites,
                            ),
                            label: Text(localization.recruitingNavFavorites),
                          ),
                          NavigationRailDestination(
                            icon: _navIcon(
                              const Icon(
                                Icons.badge_outlined,
                                key: Key('navigation-hired-people'),
                              ),
                              count: data?.hiredPeople.length ?? 0,
                              tooltip: expanded
                                  ? null
                                  : localization.hiredPeopleTitle,
                            ),
                            selectedIcon: const Icon(Icons.badge),
                            label: Text(localization.hiredPeopleTitle),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Tooltip(
                message: localization.recruitingNavSettings,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onSelectSettings,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: settingsOpen
                          ? const Color(0xFFE3ECFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: expanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Icon(
                            settingsOpen
                                ? Icons.settings
                                : Icons.settings_outlined,
                            size: 22,
                            color: settingsOpen
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          if (expanded) ...[
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                localization.recruitingNavSettings,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: settingsOpen
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: settingsOpen
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
