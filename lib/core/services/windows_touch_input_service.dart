import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Detecta touch en el monitor primario y/o fuerza el teclado virtual por preferencia.
///
/// No-op fuera de Windows. El channel solo existe en la ventana principal.
class WindowsTouchInputService extends ChangeNotifier {
  WindowsTouchInputService(this._prefs);

  final SharedPreferences _prefs;

  static const forceKeyboardKey = 'windows_onscreen_keyboard_forced';
  static const _channel = MethodChannel('punto_venta/windows_touch_input');

  bool _isPrimaryDisplayTouch = false;
  bool _loaded = false;

  bool get isPrimaryDisplayTouch => _isPrimaryDisplayTouch;
  bool get isLoaded => _loaded;

  /// Preferencia manual: mostrar botón aunque no se detecte touch.
  bool get isKeyboardForced =>
      _prefs.getBool(forceKeyboardKey) ?? false;

  /// True si el botón / teclado in-app debe estar disponible.
  bool get isKeyboardAvailable =>
      !kIsWeb &&
      Platform.isWindows &&
      (_isPrimaryDisplayTouch || isKeyboardForced);

  Future<void> setKeyboardForced(bool forced) async {
    await _prefs.setBool(forceKeyboardKey, forced);
    AppLogger.info('WindowsTouchInput: keyboardForced=$forced');
    notifyListeners();
  }

  Future<void> refresh() async {
    if (kIsWeb || !Platform.isWindows) {
      _isPrimaryDisplayTouch = false;
      _loaded = true;
      notifyListeners();
      return;
    }

    try {
      final value =
          await _channel.invokeMethod<bool>('isPrimaryDisplayTouch') ?? false;
      _isPrimaryDisplayTouch = value;
      AppLogger.info(
        'WindowsTouchInput: primaryDisplayTouch=$_isPrimaryDisplayTouch '
        'forced=$isKeyboardForced available=$isKeyboardAvailable',
      );
    } catch (e, st) {
      _isPrimaryDisplayTouch = false;
      AppLogger.error('WindowsTouchInput: isPrimaryDisplayTouch falló', e, st);
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }
}
