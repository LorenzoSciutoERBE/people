import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the [SharedPreferences] instance; overridden in `main`.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// Holds the user-selected locale, or `null` to follow the system locale.
class LocaleNotifier extends Notifier<Locale?> {
  static const String _storageKey = 'app_locale';
  static const List<String> supportedCodes = <String>['en', 'it'];

  @override
  Locale? build() {
    final code = ref.read(sharedPreferencesProvider).getString(_storageKey);
    return supportedCodes.contains(code) ? Locale(code!) : null;
  }

  Future<void> select(Locale locale) async {
    state = locale;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_storageKey, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
