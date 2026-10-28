import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/painting.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_prefs.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kCustomerDisplayWindowArg = 'customer_display';
const String kCustomerDisplaySyncMethod = 'customer_display_sync';

class WindowsCustomerDisplayService implements CustomerDisplayService {
  WindowsCustomerDisplayService(this._prefs);

  final SharedPreferences _prefs;

  WindowController? _controller;
  CustomerDisplaySnapshot _last = const CustomerDisplaySnapshot.idle();
  bool _starting = false;
  StreamSubscription<void>? _windowsChangedSub;

  @override
  bool get isEnabled =>
      _prefs.getBool(CustomerDisplayPrefs.enabledKey) ?? true;

  @override
  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(CustomerDisplayPrefs.enabledKey, enabled);
    if (!enabled) {
      await stop();
    }
  }

  @override
  Future<bool> isAvailable() async => Platform.isWindows;

  @override
  Future<void> start() async {
    if (!Platform.isWindows || !isEnabled) return;
    if (_controller != null || _starting) return;
    _starting = true;
    try {
      final placement = await _resolvePlacement();
      final argument = jsonEncode({
        'type': kCustomerDisplayWindowArg,
        'fullscreen': placement.fullscreen,
        'frame': {
          'left': placement.frame.left,
          'top': placement.frame.top,
          'width': placement.frame.width,
          'height': placement.frame.height,
        },
      });

      final controller = await WindowController.create(
        WindowConfiguration(
          hiddenAtLaunch: true,
          arguments: argument,
        ),
      );
      _controller = controller;
      await controller.show();
      _listenWindowsChanged();
      AppLogger.info(
        'CustomerDisplay Windows: ventana abierta '
        'fullscreen=${placement.fullscreen} frame=${placement.frame}',
      );
      // Dar tiempo al engine secundario a registrar el handler.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await sync(_last);
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Windows: start falló', e, st);
      _controller = null;
    } finally {
      _starting = false;
    }
  }

  void _listenWindowsChanged() {
    _windowsChangedSub ??= onWindowsChanged.listen((_) async {
      final current = _controller;
      if (current == null || !isEnabled) return;
      try {
        final all = await WindowController.getAll();
        final stillOpen = all.any((c) => c.windowId == current.windowId);
        if (!stillOpen) {
          AppLogger.info(
            'CustomerDisplay Windows: subventana cerrada — recreando',
          );
          _controller = null;
          await start();
        }
      } catch (e, st) {
        AppLogger.error(
          'CustomerDisplay Windows: onWindowsChanged falló',
          e,
          st,
        );
      }
    });
  }

  @override
  Future<void> stop() async {
    await _windowsChangedSub?.cancel();
    _windowsChangedSub = null;
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    try {
      // El handler en la subventana responde con windowManager.close().
      await controller.invokeMethod('window_close');
      AppLogger.info('CustomerDisplay Windows: ventana cerrada');
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Windows: stop falló', e, st);
      try {
        await controller.hide();
      } catch (_) {}
    }
  }

  @override
  Future<void> sync(CustomerDisplaySnapshot snapshot) async {
    _last = snapshot;
    final controller = _controller;
    if (controller == null) return;
    try {
      await controller.invokeMethod(
        kCustomerDisplaySyncMethod,
        jsonEncode(snapshot.toJson()),
      );
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Windows: sync falló', e, st);
    }
  }

  Future<_WindowPlacement> _resolvePlacement() async {
    try {
      final primary = await screenRetriever.getPrimaryDisplay();
      final displays = await screenRetriever.getAllDisplays();
      if (displays.length >= 2) {
        final secondary = displays.firstWhere(
          (d) => d.id != primary.id,
          orElse: () => displays.last,
        );
        final pos = secondary.visiblePosition ?? Offset.zero;
        final size = secondary.visibleSize ?? secondary.size;
        return _WindowPlacement(
          frame: Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height),
          fullscreen: true,
        );
      }

      final pos = primary.visiblePosition ?? Offset.zero;
      final size = primary.visibleSize ?? primary.size;
      final width = (size.width * 0.45).clamp(640.0, 1100.0);
      final height = (size.height * 0.7).clamp(480.0, 900.0);
      return _WindowPlacement(
        frame: Rect.fromLTWH(
          pos.dx + size.width - width - 24,
          pos.dy + (size.height - height) / 2,
          width,
          height,
        ),
        fullscreen: false,
      );
    } catch (e, st) {
      AppLogger.error(
        'CustomerDisplay Windows: no se pudieron leer displays',
        e,
        st,
      );
      return const _WindowPlacement(
        frame: Rect.fromLTWH(100, 100, 900, 700),
        fullscreen: false,
      );
    }
  }
}

class _WindowPlacement {
  const _WindowPlacement({
    required this.frame,
    required this.fullscreen,
  });

  final Rect frame;
  final bool fullscreen;
}
