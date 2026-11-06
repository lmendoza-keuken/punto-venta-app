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
    this.preferBoundsFullscreen = false,
  });

  final Widget child;

  /// Al salir de fullscreen, restaura este frame (útil en 2º monitor).
  final Rect? windowedBounds;

  /// Si true, no llama [WindowManager.setFullScreen] (inestable con
  /// desktop_multi_window). Usa bounds + frameless en su lugar.
  final bool preferBoundsFullscreen;

  @override
  State<WindowsFullscreenHotkeys> createState() =>
      _WindowsFullscreenHotkeysState();
}

class _WindowsFullscreenHotkeysState extends State<WindowsFullscreenHotkeys> {
  bool _toggling = false;
  bool _boundsFs = true;

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
      if (widget.preferBoundsFullscreen) {
        await _toggleBoundsFullscreen();
        return;
      }

      final isFs = await windowManager.isFullScreen();
      if (isFs) {
        await windowManager.setFullScreen(false);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final bounds = widget.windowedBounds;
        if (bounds != null) {
          await windowManager.setBounds(bounds);
        } else {
          await windowManager.maximize();
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

  Future<void> _toggleBoundsFullscreen() async {
    final bounds = widget.windowedBounds;
    if (_boundsFs) {
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      if (bounds != null) {
        // Ventana más chica centrada en el mismo monitor.
        final nested = Rect.fromCenter(
          center: bounds.center,
          width: (bounds.width * 0.85).clamp(640, bounds.width),
          height: (bounds.height * 0.85).clamp(480, bounds.height),
        );
        await windowManager.setBounds(nested);
      }
      _boundsFs = false;
      AppLogger.info('WindowsFullscreenHotkeys: salió de bounds-FS (F11)');
    } else {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setAsFrameless();
      if (bounds != null) {
        await windowManager.setBounds(bounds);
      }
      _boundsFs = true;
      AppLogger.info('WindowsFullscreenHotkeys: entró a bounds-FS (F11)');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
