import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/common/camera_lcd_coordinator.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/common/scan_beep.dart';

/// Escáner continuo (estilo pistola).
///
/// Sesión montada mientras [enabled]. Tras cada código: slot LCD
/// (`pause` analyzer → onCode → wait paint OK/timeout → `start`). Sin dispose.
class AutoBarcodeScannerHost extends StatefulWidget {
  final bool enabled;
  final Future<void> Function(String code) onCode;
  final Duration cooldown;

  const AutoBarcodeScannerHost({
    super.key,
    required this.enabled,
    required this.onCode,
    this.cooldown = const Duration(milliseconds: 900),
  });

  static const List<BarcodeFormat> supportedFormats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.itf14,
    BarcodeFormat.codabar,
  ];

  @override
  State<AutoBarcodeScannerHost> createState() => _AutoBarcodeScannerHostState();
}

class _AutoBarcodeScannerHostState extends State<AutoBarcodeScannerHost> {
  MobileScannerController? _controller;
  bool _busy = false;
  bool _surfaceMounted = false;
  bool _spiQuiet = CameraLcdCoordinator.spiQuietRequested;
  DateTime? _lastAcceptedAt;
  StreamSubscription<bool>? _spiSub;
  Future<void> _cameraOp = Future<void>.value();

  bool get _wantAnalyzing =>
      widget.enabled && !_spiQuiet && !_busy;

  @override
  void initState() {
    super.initState();
    CameraLcdCoordinator.autoCameraActive = widget.enabled;
    _spiSub = CameraLcdCoordinator.spiQuietChanges.listen((quiet) {
      if (!mounted) return;
      _spiQuiet = quiet;
      _syncAnalyzer();
    });
    _syncCamera();
  }

  @override
  void didUpdateWidget(covariant AutoBarcodeScannerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      CameraLcdCoordinator.autoCameraActive = widget.enabled;
      _syncCamera();
    }
  }

  @override
  void dispose() {
    CameraLcdCoordinator.autoCameraActive = false;
    CameraLcdCoordinator.endScanLcdSlot();
    unawaited(_spiSub?.cancel());
    _cameraOp = _cameraOp.catchError((_) {}).then((_) => _tearDown());
    super.dispose();
  }

  void _syncCamera() {
    if (widget.enabled) {
      _enqueue(() async {
        await _ensureMounted();
        await _syncAnalyzerInner();
      });
    } else {
      _enqueue(() => _tearDown());
    }
  }

  void _syncAnalyzer() {
    _enqueue(() => _syncAnalyzerInner());
  }

  void _enqueue(Future<void> Function() op) {
    _cameraOp = _cameraOp.catchError((_) {}).then((_) => op());
  }

  MobileScannerController _createController() {
    return MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 400,
      facing: CameraFacing.back,
      cameraResolution: const Size(640, 480),
      formats: AutoBarcodeScannerHost.supportedFormats,
      returnImage: false,
    );
  }

  Future<void> _ensureMounted() async {
    if (!mounted || !widget.enabled) return;
    if (_surfaceMounted && _controller != null) return;
    _controller ??= _createController();
    if (!_surfaceMounted) {
      setState(() => _surfaceMounted = true);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> _syncAnalyzerInner() async {
    if (!mounted || !widget.enabled) return;
    final controller = _controller;
    if (controller == null) {
      CameraLcdCoordinator.reportAnalyzerQuiet();
      return;
    }

    if (_wantAnalyzing) {
      final state = controller.value;
      if (state.isRunning || state.isStarting) return;
      try {
        await controller.start();
      } on MobileScannerException catch (e) {
        if (e.errorCode == MobileScannerErrorCode.controllerInitializing) {
          return;
        }
        try {
          await controller.dispose();
        } catch (_) {}
        if (!mounted || !_wantAnalyzing) return;
        _controller = _createController();
        setState(() => _surfaceMounted = true);
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || !_wantAnalyzing) return;
        try {
          await _controller!.start();
        } catch (_) {}
      } catch (_) {}
      return;
    }

    try {
      while (controller.value.isStarting) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
      }
      if (controller.value.isRunning) {
        try {
          await controller.pause();
        } catch (_) {
          try {
            await controller.stop();
          } catch (_) {}
        }
      }
    } finally {
      CameraLcdCoordinator.reportAnalyzerQuiet();
    }
  }

  Future<void> _tearDown() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        while (controller.value.isStarting) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
        if (controller.value.isRunning) {
          try {
            await controller.stop();
          } catch (_) {}
        }
        await controller.dispose();
      } catch (_) {}
    }
    if (_surfaceMounted && mounted) {
      setState(() => _surfaceMounted = false);
    } else {
      _surfaceMounted = false;
    }
    CameraLcdCoordinator.reportAnalyzerQuiet();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (!_wantAnalyzing || _busy) return;

    final raw = capture.barcodes
        .map((b) => b.rawValue?.trim())
        .whereType<String>()
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (raw.isEmpty) return;

    final now = DateTime.now();
    final lastAt = _lastAcceptedAt;
    if (lastAt != null && now.difference(lastAt) < widget.cooldown) {
      return;
    }

    _busy = true;
    _lastAcceptedAt = now;
    // Slot: pause analyzer mientras carrito + LCD pintan.
    // Más aire: el binder debounced + SPI gap; no rearrmar cámara a los 1s.
    CameraLcdCoordinator.beginScanLcdSlot(
      timeout: const Duration(milliseconds: 2200),
    );
    _spiQuiet = true;
    _syncAnalyzer();

    try {
      await _cameraOp.catchError((_) {});
      ScanBeep.play();
      await widget.onCode(raw);
      await CameraLcdCoordinator.waitForScanLcdSlot();
    } finally {
      CameraLcdCoordinator.endScanLcdSlot();
      _spiQuiet = CameraLcdCoordinator.spiQuietRequested;
      if (mounted) {
        _busy = false;
        _syncCamera();
      } else {
        _busy = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_surfaceMounted || _controller == null) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: Opacity(
        opacity: 0,
        child: SizedBox(
          width: 1,
          height: 1,
          child: MobileScanner(
            controller: _controller!,
            onDetect: _onDetect,
          ),
        ),
      ),
    );
  }
}
