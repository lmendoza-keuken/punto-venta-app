import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';

/// Detecta si el monitor primario de Windows es táctil (solo logging / diagnóstico).
///
/// El botón de teclado en pantalla ya no depende de esto: siempre se muestra en Windows.
class WindowsTouchInputService {
  WindowsTouchInputService();

  static const _channel = MethodChannel('punto_venta/windows_touch_input');

  bool _isPrimaryDisplayTouch = false;
  bool _loaded = false;

  bool get isPrimaryDisplayTouch => _isPrimaryDisplayTouch;
  bool get isLoaded => _loaded;

  Future<void> refresh() async {
    if (kIsWeb || !Platform.isWindows) {
      _isPrimaryDisplayTouch = false;
      _loaded = true;
      return;
    }

    try {
      final value =
          await _channel.invokeMethod<bool>('isPrimaryDisplayTouch') ?? false;
      _isPrimaryDisplayTouch = value;
      AppLogger.info(
        'WindowsTouchInput: primaryDisplayTouch=$_isPrimaryDisplayTouch',
      );
    } catch (e, st) {
      _isPrimaryDisplayTouch = false;
      AppLogger.error('WindowsTouchInput: isPrimaryDisplayTouch falló', e, st);
    } finally {
      _loaded = true;
    }
  }
}
