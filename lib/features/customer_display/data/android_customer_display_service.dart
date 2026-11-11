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
  DateTime? _nextStartAttempt;
  int _startFailCount = 0;
  bool _startInFlight = false;
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
      _clearStartBackoff();
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
    if (_startInFlight) return;
    final gate = _nextStartAttempt;
    if (gate != null && DateTime.now().isBefore(gate)) return;

    _startInFlight = true;
    try {
      _startReconnectPolling();

      // PTA0130: LCD SPI vía Binder SubScreen (no es Display Android).
      // _started solo después de un frame real. Si falla tras init, shutdown
      // limpia la nieve; si no, el carro no actualiza y el LCD queda 40s+ en basura.
      if (await _hasSubScreen()) {
        AppLogger.info('CustomerDisplay Android: SubScreen — empujando primer frame');
        final shown = await PtaSubScreen.showSnapshot(_last);
        final realFrame = shown.ok && shown.error != 'superseded';
        if (!realFrame) {
          AppLogger.info(
            'CustomerDisplay Android: primer frame SubScreen falló '
            'code=${shown.code} error=${shown.error}',
          );
          await _abortSubScreenStart();
          return;
        }
        _backend = _AndroidDisplayBackend.subScreen;
        _started = true;
        _clearStartBackoff();
        AppLogger.info('CustomerDisplay Android: SubScreen LCD activo');
        return;
      }

      final secondary = await _resolveSecondaryDisplay();
      if (secondary == null) {
        AppLogger.info(
          'CustomerDisplay Android: sin Presentation ni SubScreen',
        );
        _markStartFailed();
        return;
      }

      final displayId = secondary.displayId;
      if (displayId == null) {
        AppLogger.info('CustomerDisplay Android: displayId nulo');
        _markStartFailed();
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
        _markStartFailed();
        return;
      }

      _secondaryDisplayId = displayId;
      _backend = _AndroidDisplayBackend.presentation;
      _started = true;
      _clearStartBackoff();
      AppLogger.info(
        'CustomerDisplay Android: Presentation abierta displayId=$displayId',
      );
      await sync(_last);
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Android: start falló', e, st);
      _markStartFailed();
    } finally {
      _startInFlight = false;
    }
  }

  void _clearStartBackoff() {
    _startFailCount = 0;
    _nextStartAttempt = null;
  }

  void _markStartFailed() {
    _started = false;
    _secondaryDisplayId = null;
    _backend = _AndroidDisplayBackend.none;
    _startFailCount += 1;
    // Reintento casi inmediato: el SPI suele liberarse tras el primer BUSY.
    final seconds = _startFailCount <= 2 ? 1 : _startFailCount.clamp(1, 3);
    _nextStartAttempt = DateTime.now().add(Duration(seconds: seconds));
    AppLogger.info(
      'CustomerDisplay Android: backoff start ${seconds}s '
      '(fallo #$_startFailCount)',
    );
  }

  Future<void> _abortSubScreenStart() async {
    _markStartFailed();
    // No llamar shutdown acá: pelea con un init nativo aún en curso y
    // deja ERR_BUSY. El próximo start hace release previo en doInit.
  }

  @override
  Future<void> stop() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _adRotateTimer?.cancel();
    _adRotateTimer = null;
    _clearStartBackoff();
    final backend = _backend;
    final displayId = _secondaryDisplayId;
    _started = false;
    _secondaryDisplayId = null;
    _backend = _AndroidDisplayBackend.none;

    // Negro + settle + release en un solo IPC nativo (evita race showColor/release).
    try {
      await PtaSubScreen.shutdown();
      AppLogger.info('CustomerDisplay Android: SubScreen shutdown');
    } catch (e, st) {
      AppLogger.error(
        'CustomerDisplay Android: SubScreen shutdown falló',
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
    if (!_started) {
      // No encadenar start() en cada scan si el LCD está fallando: eso
      // re-captura overlay + SPI y congela la tablet. El poll de reconnect
      // reintenta con backoff.
      if (isEnabled && !_startInFlight) {
        unawaited(start());
      }
      return;
    }

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
    // Solo cuando !_started. Cada 5s (antes 1s) para no saturar getInfo/SPI.
    _reconnectTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!isEnabled || _started || _startInFlight) return;
      final available = await isAvailable();
      if (available) {
        AppLogger.info(
          'CustomerDisplay Android: reconnect — display detectado',
        );
        await start();
      }
    });
  }
}
