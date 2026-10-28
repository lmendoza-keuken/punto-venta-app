import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_prefs.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AndroidCustomerDisplayService implements CustomerDisplayService {
  AndroidCustomerDisplayService(this._prefs);

  final SharedPreferences _prefs;
  final DisplayManager _displayManager = DisplayManager();

  int? _secondaryDisplayId;
  CustomerDisplaySnapshot _last = const CustomerDisplaySnapshot.idle();
  bool _started = false;
  Timer? _reconnectTimer;

  @override
  bool get isEnabled =>
      _prefs.getBool(CustomerDisplayPrefs.enabledKey) ?? true;

  @override
  Future<void> setEnabled(bool enabled) async {
    await _prefs.setBool(CustomerDisplayPrefs.enabledKey, enabled);
    if (!enabled) {
      await stop();
    } else {
      _startReconnectPolling();
      await start();
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final target = await _resolveSecondaryDisplay();
    return target != null;
  }

  @override
  Future<void> start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (!isEnabled || _started) return;

    try {
      _startReconnectPolling();
      final secondary = await _resolveSecondaryDisplay();
      if (secondary == null) {
        AppLogger.info('CustomerDisplay Android: sin display secundario');
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
      _started = true;
      AppLogger.info(
        'CustomerDisplay Android: Presentation abierta displayId=$displayId',
      );
      await sync(_last);
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Android: start falló', e, st);
      _started = false;
      _secondaryDisplayId = null;
    }
  }

  @override
  Future<void> stop() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final displayId = _secondaryDisplayId;
    _started = false;
    _secondaryDisplayId = null;
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
    try {
      await _displayManager.transferDataToPresentation(
        jsonEncode(snapshot.toJson()),
      );
    } catch (e, st) {
      AppLogger.error('CustomerDisplay Android: sync falló', e, st);
    }
  }

  /// Prefiere categoría PRESENTATION; si no hay, usa el 2º display de la lista total.
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
      AppLogger.error(
        'CustomerDisplay Android: resolve display falló',
        e,
        st,
      );
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
        AppLogger.info('CustomerDisplay Android: reconnect — display detectado');
        await start();
      } else if (!available && _started) {
        AppLogger.info('CustomerDisplay Android: display perdido');
        _started = false;
        _secondaryDisplayId = null;
      }
    });
  }
}
