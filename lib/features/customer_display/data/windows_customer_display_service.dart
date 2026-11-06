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
import 'package:window_manager/window_manager.dart';

const String kCustomerDisplayWindowArg = 'customer_display';
const String kCustomerDisplaySyncMethod = 'customer_display_sync';

class WindowsCustomerDisplayService
    with WindowListener
    implements CustomerDisplayService {
  WindowsCustomerDisplayService(this._prefs);

  final SharedPreferences _prefs;

  WindowController? _controller;
  CustomerDisplaySnapshot _last = const CustomerDisplaySnapshot.idle();
  bool _starting = false;
  bool _stopping = false;
  bool _closingApp = false;
  bool _closeHookInstalled = false;
  StreamSubscription<void>? _windowsChangedSub;
  final StreamController<bool> _enabledChanges =
      StreamController<bool>.broadcast();

  @override
  bool get isPlatformSupported => Platform.isWindows;

  @override
  Stream<bool> get enabledChanges => _enabledChanges.stream;

  @override
  bool get isEnabled => CustomerDisplayPrefs.isEnabled(_prefs);

  @override
  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(CustomerDisplayPrefs.enabledKey, enabled);
    if (!enabled) {
      await stop();
    } else {
      await start();
    }
    if (!_enabledChanges.isClosed) {
      _enabledChanges.add(enabled);
    }
    AppLogger.info(
      'CustomerDisplay Windows: preferencia enabled=$enabled '
      '(cache local de este equipo)',
    );
  }

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isWindows) return false;
    final placement = await _resolveSecondaryFullscreenPlacement();
    return placement != null;
  }

  @override
  Future<void> start() async {
    if (!Platform.isWindows || !isEnabled) return;
    if (_controller != null || _starting || _closingApp) return;
    _starting = true;
    try {
      final placement = await _resolveSecondaryFullscreenPlacement();
      if (placement == null) {
        AppLogger.info(
          'CustomerDisplay Windows: sin 2º monitor usable — '
          'no se abre la ventana cliente',
        );
        return;
      }

      // bounds del 2º monitor — nunca setFullScreen / setAsFrameless.
      final argument = jsonEncode({
        'type': kCustomerDisplayWindowArg,
        'fullscreen': false,
        'frame': {
          'left': placement.frame.left,
          'top': placement.frame.top,
          'width': placement.frame.width,
          'height': placement.frame.height,
        },
      });

      AppLogger.info(
        'CustomerDisplay Windows: creando subventana frame=${placement.frame}',
      );
      final controller = await WindowController.create(
        WindowConfiguration(hiddenAtLaunch: true, arguments: argument),
      );
      _controller = controller;
      AppLogger.info(
        'CustomerDisplay Windows: subventana creada id=${controller.windowId}',
      );
      await controller.show();
      // Esperar a que el 2º engine registre plugins/handler antes de IPC
      // o de instalar el hook de cierre (evita falsos onWindowClose).
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (_closingApp || _stopping) return;
      _listenWindowsChanged();
      await _ensureMainCloseHook();
      AppLogger.info(
        'CustomerDisplay Windows: ventana abierta (bounds) '
        'en 2º monitor frame=${placement.frame}',
      );
      await sync(_last);
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Windows: start falló', e, st);
      _controller = null;
    } finally {
      _starting = false;
    }
  }

  /// Intercepta el X de la ventana principal: primero cierra la de cliente.
  Future<void> _ensureMainCloseHook() async {
    if (_closeHookInstalled || !Platform.isWindows) return;
    _closeHookInstalled = true;
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    AppLogger.info(
      'CustomerDisplay Windows: hook de cierre de ventana principal activo',
    );
  }

  @override
  void onWindowClose() {
    unawaited(_handleMainWindowClose());
  }

  Future<void> _handleMainWindowClose() async {
    if (_closingApp) return;
    _closingApp = true;
    _stopping = true;
    AppLogger.info(
      'CustomerDisplay Windows: cerrando principal → stop pantalla cliente',
    );

    await _windowsChangedSub?.cancel();
    _windowsChangedSub = null;
    final controller = _controller;
    _controller = null;

    if (controller != null) {
      try {
        await controller.hide();
      } catch (_) {}
      try {
        await controller
            .invokeMethod('window_close')
            .timeout(const Duration(milliseconds: 250), onTimeout: () => null);
      } catch (e, st) {
        AppLogger.error(
          'CustomerDisplay Windows: window_close en salida falló',
          e,
          st,
        );
      }
    }

    try {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    } catch (e, st) {
      AppLogger.error(
        'CustomerDisplay Windows: cierre ventana principal falló',
        e,
        st,
      );
    }
  }

  void _listenWindowsChanged() {
    _windowsChangedSub ??= onWindowsChanged.listen((_) async {
      final current = _controller;
      if (_stopping || _closingApp || _starting || current == null || !isEnabled) {
        return;
      }
      try {
        // Pequeño debounce: al crear la subventana onWindowsChanged dispara
        // antes de que el id quede estable; recrear en ese momento tumba todo.
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (_stopping || _closingApp || _starting || _controller == null) {
          return;
        }
        final tracked = _controller!;
        final all = await WindowController.getAll();
        final stillOpen = all.any((c) => c.windowId == tracked.windowId);
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
    if (_stopping) return;
    _stopping = true;
    await _windowsChangedSub?.cancel();
    _windowsChangedSub = null;
    final controller = _controller;
    _controller = null;
    try {
      if (controller != null) {
        await _closeCustomerController(controller);
      }
      // Por si quedó alguna subventana huérfana (mismo type en arguments).
      await _closeAllCustomerWindows(exceptId: null);
      AppLogger.info('CustomerDisplay Windows: ventana cerrada');
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Windows: stop falló', e, st);
    } finally {
      _stopping = false;
    }
  }

  Future<void> _closeCustomerController(WindowController controller) async {
    try {
      await controller.hide();
    } catch (_) {}
    try {
      await controller
          .invokeMethod('window_close')
          .timeout(const Duration(milliseconds: 250), onTimeout: () => null);
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Windows: window_close falló', e, st);
    }
  }

  Future<void> _closeAllCustomerWindows({String? exceptId}) async {
    try {
      final all = await WindowController.getAll();
      final targets = all
          .where(
            (c) =>
                (exceptId == null || c.windowId != exceptId) &&
                _isCustomerDisplayWindow(c),
          )
          .toList();
      await Future.wait(targets.map(_closeCustomerController));
    } catch (e, st) {
      AppLogger.error(
        'CustomerDisplay Windows: barrido de subventanas falló',
        e,
        st,
      );
    }
  }

  bool _isCustomerDisplayWindow(WindowController c) {
    final raw = c.arguments;
    if (raw.isEmpty) return false;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['type'] == kCustomerDisplayWindowArg;
    } catch (_) {
      return raw.contains(kCustomerDisplayWindowArg);
    }
  }

  @override
  Future<void> sync(CustomerDisplaySnapshot snapshot) async {
    _last = snapshot;
    if (_controller == null) {
      await start();
      return;
    }
    try {
      await _controller!.invokeMethod(
        kCustomerDisplaySyncMethod,
        jsonEncode(snapshot.toJson()),
      );
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Windows: sync falló', e, st);
    }
  }

  Future<_WindowPlacement?> _resolveSecondaryFullscreenPlacement() async {
    try {
      final primary = await screenRetriever.getPrimaryDisplay();
      final displays = await screenRetriever.getAllDisplays();
      final primaryPos = primary.visiblePosition ?? Offset.zero;

      AppLogger.info(
        'CustomerDisplay Windows: displays=${displays.length} '
        'primary id=${primary.id} pos=$primaryPos '
        'size=${primary.visibleSize ?? primary.size}',
      );
      for (final d in displays) {
        AppLogger.info(
          '  display id=${d.id} pos=${d.visiblePosition} '
          'size=${d.visibleSize ?? d.size}',
        );
      }

      if (displays.length < 2) return null;

      final secondary = _pickSecondary(displays, primary);
      if (secondary == null) return null;

      final pos = secondary.visiblePosition ?? Offset.zero;
      final size = secondary.visibleSize ?? secondary.size;
      final sameOrigin = (pos - primaryPos).distance < 8;
      if (sameOrigin) {
        AppLogger.info(
          'CustomerDisplay Windows: 2º monitor reporta el mismo origen '
          'que el primario — no se abre (posición inválida)',
        );
        return null;
      }

      return _WindowPlacement(
        frame: Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height),
        fullscreen: true,
      );
    } catch (e, st) {
      AppLogger.error(
        'CustomerDisplay Windows: no se pudieron leer displays',
        e,
        st,
      );
      return null;
    }
  }

  /// Elige el monitor que no es el primario (por id o por posición).
  Display? _pickSecondary(List<Display> displays, Display primary) {
    if (displays.length < 2) return null;

    final primaryPos = primary.visiblePosition ?? Offset.zero;

    final byId = displays.where((d) => d.id != primary.id).toList();
    if (byId.isNotEmpty) {
      byId.sort((a, b) {
        final ap = a.visiblePosition ?? Offset.zero;
        final bp = b.visiblePosition ?? Offset.zero;
        final da = (ap - primaryPos).distance;
        final db = (bp - primaryPos).distance;
        return db.compareTo(da); // más lejos del primario primero
      });
      return byId.first;
    }

    // Mismo id raro: tomar el de distinta posición.
    final byPos = displays.where((d) {
      final p = d.visiblePosition ?? Offset.zero;
      return (p - primaryPos).distance > 8;
    }).toList();
    if (byPos.isNotEmpty) return byPos.first;

    return displays.last;
  }
}

class _WindowPlacement {
  const _WindowPlacement({required this.frame, required this.fullscreen});

  final Rect frame;
  final bool fullscreen;
}
