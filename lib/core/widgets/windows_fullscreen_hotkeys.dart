import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:window_manager/window_manager.dart';

/// F11 alterna “pantalla completa” ↔ ventana (Windows).
///
/// No usa [WindowManager.setFullScreen]: con el modelo de hilos por defecto
/// congela la UI (flutter/flutter#176088), y con `RunOnSeparateThread` +
/// `desktop_multi_window` tumba el proceso al abrir la 2ª pantalla.
///
/// - Principal: maximize / unmaximize + title bar.
/// - Cliente (`preferBoundsFullscreen`): bounds del monitor / ventana nested.
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

  /// Si true, usa bounds + titleBar (pantalla cliente). Si false, maximize.
  final bool preferBoundsFullscreen;

  @override
  State<WindowsFullscreenHotkeys> createState() =>
      _WindowsFullscreenHotkeysState();
}

class _WindowsFullscreenHotkeysState extends State<WindowsFullscreenHotkeys> {
  bool _toggling = false;
  bool _isExpanded = true;

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
      } else {
        await _toggleMaximizeFullscreen();
      }
    } catch (e, st) {
      AppLogger.error('WindowsFullscreenHotkeys: F11 falló', e, st);
    } finally {
      _toggling = false;
    }
  }

  Future<void> _toggleMaximizeFullscreen() async {
    if (_isExpanded) {
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      await windowManager.unmaximize();
      _isExpanded = false;
      AppLogger.info('WindowsFullscreenHotkeys: salió de maximize (F11)');
    } else {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.maximize();
      _isExpanded = true;
      AppLogger.info('WindowsFullscreenHotkeys: entró a maximize (F11)');
    }
  }

  Future<void> _toggleBoundsFullscreen() async {
    final bounds = widget.windowedBounds;
    if (_isExpanded) {
      await windowManager.setTitleBarStyle(TitleBarStyle.normal);
      if (bounds != null) {
        final nested = Rect.fromCenter(
          center: bounds.center,
          width: (bounds.width * 0.85).clamp(640, bounds.width),
          height: (bounds.height * 0.85).clamp(480, bounds.height),
        );
        await windowManager.setBounds(nested);
      }
      _isExpanded = false;
      AppLogger.info('WindowsFullscreenHotkeys: salió de bounds-FS (F11)');
    } else {
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      if (bounds != null) {
        await windowManager.setBounds(bounds);
      }
      _isExpanded = true;
      AppLogger.info('WindowsFullscreenHotkeys: entró a bounds-FS (F11)');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
