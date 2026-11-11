import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/l10n/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeWindow();
  final preferences = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const PeopleApp(),
    ),
  );
}

Future<void> _initializeWindow() async {
  if (!Platform.isWindows) return;
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
    minimumSize: Size(1100, 600),
    backgroundColor: Colors.white,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.maximize();
    await windowManager.show();
    await windowManager.focus();
  });
  await windowManager.maximize();
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (!await windowManager.isMaximized()) {
      await windowManager.maximize();
    }
  });
}
