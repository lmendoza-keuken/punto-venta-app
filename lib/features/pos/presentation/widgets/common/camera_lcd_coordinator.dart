import 'dart:async';

/// Coordina auto-cámara y LCD SubScreen en el PTA (bus SPI saturado → 61448).
///
/// - Sesiones vivas: sin dispose de cámara ni release LCD por frame.
/// - [duringSpiWrite]: micro-pause del analyzer mientras captura/`show`.
/// - [beginScanLcdSlot]: tras un scan, pause hasta paint OK o timeout.
/// - [beginBusyRecoverQuiet]: si hubo BUSY, mantiene pause mientras el binder
///   reintenta (evita que la cámara rearrme y conguele el LCD otra vez).
class CameraLcdCoordinator {
  CameraLcdCoordinator._();

  static bool autoCameraActive = false;

  static int _spiDepth = 0;
  static int _scanSlotDepth = 0;
  static bool _busyRecoverQuiet = false;
  static final StreamController<bool> _spiQuietChanges =
      StreamController<bool>.broadcast();
  static Completer<void>? _quietAck;
  static Completer<void>? _paintOkWaiter;
  static Timer? _slotTimeout;
  static Timer? _busyRecoverTimeout;

  /// true si el analyzer no debe correr.
  static bool get spiQuietRequested =>
      _spiDepth > 0 || _scanSlotDepth > 0 || _busyRecoverQuiet;

  static bool get inScanLcdSlot => _scanSlotDepth > 0;

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

  /// Tras paint LCD OK (no superseded): libera slot y recover-quiet.
  static void reportLcdPaintOk() {
    clearBusyRecoverQuiet();
    final w = _paintOkWaiter;
    if (w != null && !w.isCompleted) w.complete();
  }

  /// Cámara quieta mientras init/reintento SPI (también en boot, antes de
  /// que [autoCameraActive] pase a true).
  static void beginBusyRecoverQuiet({
    Duration timeout = const Duration(milliseconds: 2500),
  }) {
    _busyRecoverQuiet = true;
    _busyRecoverTimeout?.cancel();
    _busyRecoverTimeout = Timer(timeout, clearBusyRecoverQuiet);
    _notify();
  }

  static void clearBusyRecoverQuiet() {
    _busyRecoverTimeout?.cancel();
    _busyRecoverTimeout = null;
    if (!_busyRecoverQuiet) return;
    _busyRecoverQuiet = false;
    _notify();
  }

  /// Abre slot post-scan: analyzer en pause hasta paint OK o [timeout].
  static void beginScanLcdSlot({
    Duration timeout = const Duration(milliseconds: 2200),
  }) {
    if (!autoCameraActive) return;
    _scanSlotDepth++;
    if (_scanSlotDepth == 1) {
      _paintOkWaiter = Completer<void>();
      _slotTimeout?.cancel();
      _slotTimeout = Timer(timeout, () {
        final w = _paintOkWaiter;
        if (w != null && !w.isCompleted) w.complete();
      });
      _notify();
    }
  }

  /// Cierra un [beginScanLcdSlot] (idempotente si depth llega a 0).
  static void endScanLcdSlot() {
    if (_scanSlotDepth <= 0) return;
    _scanSlotDepth--;
    if (_scanSlotDepth <= 0) {
      _scanSlotDepth = 0;
      _slotTimeout?.cancel();
      _slotTimeout = null;
      final w = _paintOkWaiter;
      _paintOkWaiter = null;
      if (w != null && !w.isCompleted) w.complete();
      _notify();
    }
  }

  /// Espera paint OK o timeout del slot actual (no-op si no hay slot).
  static Future<void> waitForScanLcdSlot() async {
    final w = _paintOkWaiter;
    if (w == null) return;
    try {
      await w.future;
    } catch (_) {}
  }

  /// Envuelve captura + SPI: micro-pause cámara → action.
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

  // --- compat ---
  static Future<T> whileCameraPaused<T>(Future<T> Function() action) =>
      duringSpiWrite(action);

  static void reportLcdCycleFinished() => reportLcdPaintOk();
  static void reportCameraReleased() => reportAnalyzerQuiet();
  static void beginLcdExclusive() => beginScanLcdSlot();
  static void releaseCameraHold() => endScanLcdSlot();
  static bool get isPaused => spiQuietRequested;
  static bool get blocksCamera => spiQuietRequested;
  static Stream<bool> get pausedChanges => spiQuietChanges;
}
