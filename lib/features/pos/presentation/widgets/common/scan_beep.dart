import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';

/// Bip de confirmación al escanear con cámara (Android POS).
class ScanBeep {
  ScanBeep._();

  static const _channel = MethodChannel(
    'ar.com.keuken.punto_venta_app/scan_beep',
  );

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Dispara el tono nativo. Ignora fallos (no bloquea el scan).
  static Future<void> play() async {
    if (!_isAndroid) {
      await SystemSound.play(SystemSoundType.click);
      return;
    }
    try {
      await _channel.invokeMethod<void>('beep');
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
