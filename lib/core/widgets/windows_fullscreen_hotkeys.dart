import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:window_manager/window_manager.dart';

/// F11 alterna fullscreen ↔ ventana (Windows).
///
/// El fullscreen de [window_manager] no responde al F11 del sistema; hay que
/// manejarlo en Dart. Usa [HardwareKeyboard] para que funcione aunque el foco
/// esté en un TextField / scanner.
class WindowsFullscreenHotkeys extends StatefulWidget {
  const WindowsFullscreenHotkeys({
    super.key,
    required this.child,
    this.windowedBounds,
  });

  final Widget child;

  /// Al salir de fullscreen, restaura este frame (útil en 2º monitor).
  final Rect? windowedBounds;

  @override
  State<WindowsFullscreenHotkeys> createState() =>
      _WindowsFullscreenHotkeysState();
}

class _WindowsFullscreenHotkeysState extends State<WindowsFullscreenHotkeys> {
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      HardwareKeyboard.instance.addHandler(_onKey);
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      HardwareKeyboard.instance.removeHandler(_onKey);
    }
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.f11) return false;
    if (_toggling) return true;
    _toggle();
    return true;
  }

  Future<void> _toggle() async {
    if (_toggling) return;
    _toggling = true;
    try {
      final isFs = await windowManager.isFullScreen();
      if (isFs) {
        await windowManager.setFullScreen(false);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final bounds = widget.windowedBounds;
        if (bounds != null) {
          await windowManager.setBounds(bounds);
        }
        await windowManager.setTitleBarStyle(TitleBarStyle.normal);
        AppLogger.info('WindowsFullscreenHotkeys: salió de fullscreen (F11)');
      } else {
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await windowManager.setFullScreen(true);
        AppLogger.info('WindowsFullscreenHotkeys: entró a fullscreen (F11)');
      }
    } catch (e, st) {
      AppLogger.error('WindowsFullscreenHotkeys: F11 falló', e, st);
    } finally {
      _toggling = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
