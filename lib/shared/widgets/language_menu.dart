import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/locale_controller.dart';
import '../../l10n/app_localizations.dart';

/// Header action that lets the user switch between English and Italian.
class LanguageMenu extends ConsumerWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<Locale>(
      tooltip: l10n.languageTooltip,
      icon: const Icon(Icons.language),
      onSelected: (locale) => ref.read(localeProvider.notifier).select(locale),
      itemBuilder: (context) => <PopupMenuEntry<Locale>>[
        PopupMenuItem<Locale>(
          value: const Locale('en'),
          child: Text(l10n.languageEnglish),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('it'),
          child: Text(l10n.languageItalian),
        ),
      ],
    );
  }
}
