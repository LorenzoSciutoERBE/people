import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/language_menu.dart';
import '../../../../shared/widgets/window_header.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../candidate_management/presentation/widgets/candidate_board.dart';
import '../../../candidate_management/presentation/widgets/candidates_page.dart';
import '../../../candidate_management/presentation/widgets/recruiting_settings.dart';
import '../../../talent_scouting/presentation/pages/scouting_workspace.dart';
import '../../../talent_scouting/presentation/providers/talent_search_controller.dart';
import '../widgets/favorite_talents_page.dart';

enum RecruitingDestination { pipeline, candidates, search, favorites, settings }

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
    return Scaffold(
      appBar: WindowHeader(
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: localization.recruitingNavSettings,
              isSelected: settingsOpen,
              onPressed: () => _select(RecruitingDestination.settings),
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
            ),
            const LanguageMenu(),
          ],
        ),
      ),
      body: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _SideNavigation(
                  expanded: _navigationExpanded,
                  onToggle: () => setState(
                    () => _navigationExpanded = !_navigationExpanded,
                  ),
                  selectedIndex: settingsOpen
                      ? null
                      : _navigationItems.indexOf(_destination),
                  onSelected: (index) => _select(_navigationItems[index]),
                ),
                const VerticalDivider(width: 1, thickness: 1),
              ],
            ),
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
    );
  }

  Widget _buildDestination() => switch (_destination) {
    RecruitingDestination.pipeline => const CandidateBoard(),
    RecruitingDestination.candidates => const CandidatesPage(),
    RecruitingDestination.search => const ScoutingWorkspace(),
    RecruitingDestination.favorites => const FavoriteTalentsPage(),
    RecruitingDestination.settings => const RecruitingSettings(),
  };
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.expanded,
    required this.selectedIndex,
    required this.onSelected,
    required this.onToggle,
  });

  final VoidCallback onToggle;
  final bool expanded;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      child: SizedBox(
        width: expanded ? 248 : 104,
        child: Column(
          children: [
            Expanded(
              child: NavigationRail(
                extended: expanded,
                minWidth: 96,
                minExtendedWidth: 248,
                backgroundColor: Colors.white,
                selectedIndex: selectedIndex,
                labelType: expanded ? null : NavigationRailLabelType.none,
                onDestinationSelected: onSelected,
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: localization.recruitingNavToggle,
                        onPressed: onToggle,
                        icon: Icon(expanded ? Icons.menu_open : Icons.menu),
                      ),
                      if (expanded) ...[
                        const SizedBox(width: 8),
                        Text(
                          localization.recruitingNavSection.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.2,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.view_kanban_outlined),
                    selectedIcon: const Icon(Icons.view_kanban),
                    label: Text(localization.recruitingNavPipeline),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.people_outline),
                    selectedIcon: const Icon(Icons.people),
                    label: Text(localization.recruitingNavCandidates),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.manage_search_outlined),
                    selectedIcon: const Icon(Icons.manage_search),
                    label: Text(localization.recruitingNavSearch),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.star_outline),
                    selectedIcon: const Icon(Icons.star),
                    label: Text(localization.recruitingNavFavorites),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
