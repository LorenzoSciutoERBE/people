import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../l10n/app_localizations.dart';

class WindowHeader extends StatefulWidget implements PreferredSizeWidget {
  const WindowHeader({super.key, required this.action, this.showBack = false});

  final Widget action;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<WindowHeader> createState() => _WindowHeaderState();
}

class _WindowHeaderState extends State<WindowHeader> with WindowListener {
  bool _maximized = false;
  final bool _windows =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    if (_windows) {
      windowManager.addListener(this);
      _runWindowAction(() async {
        final maximized = await windowManager.isMaximized();
        if (mounted) setState(() => _maximized = maximized);
      });
    }
  }

  @override
  void dispose() {
    if (_windows) windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _maximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _maximized = false);
  }

  Future<void> _toggleMaximize() => _runWindowAction(() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    final maximized = await windowManager.isMaximized();
    if (mounted) setState(() => _maximized = maximized);
  });

  Future<void> _runWindowAction(Future<void> Function() action) async {
    try {
      await action();
    } on PlatformException catch (error, stackTrace) {
      debugPrint('Window action failed: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).windowActionFailed),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: widget.preferredSize.height,
          child: Row(
            children: [
              if (widget.showBack) const BackButton(),
              Expanded(
                child: GestureDetector(
                  key: const ValueKey('window-drag-area'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: _windows
                      ? (_) => _runWindowAction(windowManager.startDragging)
                      : null,
                  onDoubleTap: _windows ? _toggleMaximize : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/logo.jpg',
                        width: 112,
                        height: 32,
                        fit: BoxFit.contain,
                        semanticLabel: l10n.companyLogoLabel,
                      ),
                    ),
                  ),
                ),
              ),
              widget.action,
              const SizedBox(width: 8),
              if (_windows) ...[
                _control(
                  l10n.minimizeWindow,
                  Icons.horizontal_rule,
                  () => _runWindowAction(windowManager.minimize),
                ),
                _control(
                  _maximized ? l10n.restoreWindow : l10n.maximizeWindow,
                  _maximized ? Icons.filter_none : Icons.crop_square,
                  _toggleMaximize,
                ),
                _control(
                  l10n.closeWindow,
                  Icons.close,
                  () => _runWindowAction(windowManager.close),
                  close: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _control(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool close = false,
  }) => SizedBox(
    width: 44,
    height: 64,
    child: IconButton(
      tooltip: label,
      icon: Icon(icon, size: 18),
      onPressed: onPressed,
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return close ? const Color(0xFFC42B1C) : const Color(0xFFEAF0FF);
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          return close && states.contains(WidgetState.hovered)
              ? Colors.white
              : const Color(0xFF172B4D);
        }),
      ),
    ),
  );
}
