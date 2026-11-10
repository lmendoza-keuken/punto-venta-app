import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/customer_display/data/pta_sub_screen.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_prefs.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _AndroidDisplayBackend { none, presentation, subScreen }

class AndroidCustomerDisplayService implements CustomerDisplayService {
  AndroidCustomerDisplayService(this._prefs);

  final SharedPreferences _prefs;
  final DisplayManager _displayManager = DisplayManager();

  int? _secondaryDisplayId;
  CustomerDisplaySnapshot _last = const CustomerDisplaySnapshot.idle();
  bool _started = false;
  _AndroidDisplayBackend _backend = _AndroidDisplayBackend.none;
  Timer? _reconnectTimer;
  Timer? _adRotateTimer;
  final StreamController<bool> _enabledChanges =
      StreamController<bool>.broadcast();

  @override
  bool get isPlatformSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
      _startReconnectPolling();
      await start();
    }
    if (!_enabledChanges.isClosed) {
      _enabledChanges.add(enabled);
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    if (await _hasSubScreen()) return true;
    final target = await _resolveSecondaryDisplay();
    return target != null;
  }

  @override
  Future<void> start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (!isEnabled) return;

    if (_started && _backend == _AndroidDisplayBackend.subScreen) {
      await PtaSubScreen.showSnapshot(_last);
      return;
    }
    if (_started) return;

    try {
      _startReconnectPolling();

      // PTA0130: LCD SPI vía Binder SubScreen (no es Display Android).
      // El contenido viene del carrito real (CustomerDisplayBinder → sync).
      if (await _hasSubScreen()) {
        final init = await PtaSubScreen.init();
        if (!init.ok) {
          AppLogger.info(
            'CustomerDisplay Android: SubScreen init falló '
            'code=${init.code} error=${init.error}',
          );
          return;
        }
        _backend = _AndroidDisplayBackend.subScreen;
        _started = true;
        AppLogger.info('CustomerDisplay Android: SubScreen LCD activo');
        await PtaSubScreen.showSnapshot(_last);
        return;
      }

      final secondary = await _resolveSecondaryDisplay();
      if (secondary == null) {
        AppLogger.info(
          'CustomerDisplay Android: sin Presentation ni SubScreen',
        );
        return;
      }

      final displayId = secondary.displayId;
      if (displayId == null) {
        AppLogger.info('CustomerDisplay Android: displayId nulo');
        return;
      }

      final shown = await _displayManager.showSecondaryDisplay(
        displayId: displayId,
        routerName: 'presentation',
      );
      if (shown != true) {
        AppLogger.info(
          'CustomerDisplay Android: showSecondaryDisplay devolvió $shown',
        );
        return;
      }

      _secondaryDisplayId = displayId;
      _backend = _AndroidDisplayBackend.presentation;
      _started = true;
      AppLogger.info(
        'CustomerDisplay Android: Presentation abierta displayId=$displayId',
      );
      await sync(_last);
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Android: start falló', e, st);
      _started = false;
      _secondaryDisplayId = null;
      _backend = _AndroidDisplayBackend.none;
    }
  }

  @override
  Future<void> stop() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _adRotateTimer?.cancel();
    _adRotateTimer = null;
    final backend = _backend;
    final displayId = _secondaryDisplayId;
    _started = false;
    _secondaryDisplayId = null;
    _backend = _AndroidDisplayBackend.none;

    // Limpia el panel y apaga el LCD SPI al cerrar (app / logout / toggle off).
    try {
      await PtaSubScreen.showColor(0xFF000000, label: '');
    } catch (_) {}
    try {
      await PtaSubScreen.release();
      AppLogger.info('CustomerDisplay Android: SubScreen release');
    } catch (e, st) {
      AppLogger.error(
        'CustomerDisplay Android: SubScreen release falló',
        e,
        st,
      );
    }

    if (backend == _AndroidDisplayBackend.subScreen) return;

    if (displayId == null) return;
    try {
      await _displayManager.hideSecondaryDisplay(displayId: displayId);
      AppLogger.info('CustomerDisplay Android: Presentation cerrada');
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Android: stop falló', e, st);
    }
  }

  @override
  Future<void> sync(CustomerDisplaySnapshot snapshot) async {
    _last = snapshot;
    if (!_started) return;

    if (_backend == _AndroidDisplayBackend.subScreen) {
      await _syncSubScreen(snapshot);
      return;
    }

    try {
      await _displayManager.transferDataToPresentation(
        jsonEncode(snapshot.toJson()),
      );
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Android: sync falló', e, st);
    }
  }

  Future<void> _syncSubScreen(CustomerDisplaySnapshot snapshot) async {
    try {
      await PtaSubScreen.showSnapshot(snapshot);
      _scheduleAdRotation(snapshot);
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Android: SubScreen sync falló', e, st);
    }
  }

  void _scheduleAdRotation(CustomerDisplaySnapshot snapshot) {
    _adRotateTimer?.cancel();
    _adRotateTimer = null;
    if (snapshot.mode != CustomerDisplayMode.advertising) return;
    if (snapshot.adProducts.length < 2) return;

    // Misma cadencia que CustomerDisplayAdCarousel (_autoPlay = 4s).
    _adRotateTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!_started || _backend != _AndroidDisplayBackend.subScreen) return;
      if (_last.mode != CustomerDisplayMode.advertising) return;
      if (_last.adProducts.length < 2) return;
      try {
        await PtaSubScreen.showSnapshot(_last);
      } catch (e, st) {
        AppLogger.error(
          'CustomerDisplay Android: rotación publicidad falló',
          e,
          st,
        );
      }
    });
  }

  Future<bool> _hasSubScreen() async {
    try {
      final info = await PtaSubScreen.getInfo();
      return info.available;
    } catch (_) {
      return false;
    }
  }

  /// Prefiere categoría PRESENTATION; si no hay, usa el 2º display de la lista.
  Future<Display?> _resolveSecondaryDisplay() async {
    try {
      final presentation = await _displayManager.getDisplays(
        category: DISPLAY_CATEGORY_PRESENTATION,
      );
      if (presentation != null && presentation.isNotEmpty) {
        return presentation.first;
      }

      final all = await _displayManager.getDisplays();
      if (all != null && all.length >= 2) {
        return all[1];
      }
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Android: resolve display falló', e, st);
    }
    return null;
  }

  void _startReconnectPolling() {
    _reconnectTimer?.cancel();
    if (!isEnabled) return;
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!isEnabled) return;
      final available = await isAvailable();
      if (available && !_started) {
        AppLogger.info(
          'CustomerDisplay Android: reconnect — display detectado',
        );
        await start();
      } else if (!available && _started) {
        AppLogger.info('CustomerDisplay Android: display perdido');
        _started = false;
        _secondaryDisplayId = null;
        _backend = _AndroidDisplayBackend.none;
      }
    });
  }
}
