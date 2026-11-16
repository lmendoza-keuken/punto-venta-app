import 'dart:async';

/// Coordina auto-cámara y LCD sin “matar” ninguno.
///
/// Estrategia PTA:
/// - Ambos siguen vivos (PlatformView montado, sesión LCD sin re-init).
/// - Solo durante el SPI `showBitmap` se pide un **micro-pause** de análisis
///   (`MobileScannerController.pause`) ~cientos de ms. No es un hold largo.
/// - El binder usa [autoCameraActive] para debounce un poco mayor.
class CameraLcdCoordinator {
  CameraLcdCoordinator._();

  static bool autoCameraActive = false;

  static int _spiDepth = 0;
  static final StreamController<bool> _spiQuietChanges =
      StreamController<bool>.broadcast();
  static Completer<void>? _quietAck;

  /// true mientras el LCD está en el write SPI (análisis en pausa).
  static bool get spiQuietRequested => _spiDepth > 0;

  static Stream<bool> get spiQuietChanges => _spiQuietChanges.stream;

  static void _notify() {
    if (!_spiQuietChanges.isClosed) {
      _spiQuietChanges.add(spiQuietRequested);
    }
  }

  /// Host: ya pausó el análisis (o no hay cámara).
  static void reportAnalyzerQuiet() {
    final ack = _quietAck;
    if (ack != null && !ack.isCompleted) ack.complete();
  }

  /// Envuelve el paint SPI: micro-pause de cámara → action → resume.
  static Future<T> duringSpiWrite<T>(Future<T> Function() action) async {
    if (!autoCameraActive) return action();

    _spiDepth++;
    if (_spiDepth == 1) {
      _quietAck = Completer<void>();
      _notify();
      try {
        await (_quietAck?.future)?.timeout(
          const Duration(milliseconds: 280),
          onTimeout: () {},
        );
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    try {
      return await action();
    } finally {
      _spiDepth--;
      if (_spiDepth <= 0) {
        _spiDepth = 0;
        _quietAck = null;
        _notify();
      }
    }
  }

  // --- compat (no-ops / aliases viejos) ---
  static Future<T> whileCameraPaused<T>(Future<T> Function() action) =>
      duringSpiWrite(action);

  static void reportLcdCycleFinished() {}
  static void reportCameraReleased() => reportAnalyzerQuiet();
  static void beginLcdExclusive() {}
  static void releaseCameraHold() {}
  static bool get isPaused => spiQuietRequested;
  static bool get blocksCamera => spiQuietRequested;
  static Stream<bool> get pausedChanges => spiQuietChanges;
}
