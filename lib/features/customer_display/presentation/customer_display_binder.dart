import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_sync.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

/// Sync cajero → pantalla cliente.
class CustomerDisplayBinder extends StatefulWidget {
  const CustomerDisplayBinder({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<CustomerDisplayBinder> createState() => _CustomerDisplayBinderState();
}

class _CustomerDisplayBinderState extends State<CustomerDisplayBinder> {
  /// Pausa tras el último scan antes de IPC. Más alto = cajero más fluido;
  /// la vista cliente se actualiza un frame después del burst.
  static const _cartIdleDebounce = Duration(milliseconds: 90);

  late final CustomerDisplayService _service;
  Timer? _doneTimer;
  Timer? _cartIdleTimer;
  bool _holdingDone = false;
  bool _syncInFlight = false;
  bool _dirty = false;
  String? _pendingQrLabel;
  String? _pendingQrPayload;
  bool _pendingClearQr = false;
  CustomerDisplaySnapshot _lastSent = const CustomerDisplaySnapshot.idle();

  @override
  void initState() {
    super.initState();
    _service = di.sl<CustomerDisplayService>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      if (!_service.isEnabled) return;
      await _service.start();
      if (!mounted) return;
      _requestSync(immediate: true);
    } catch (e, st) {
      AppLogger.error('CustomerDisplayBinder: bootstrap falló', e, st);
    }
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    _cartIdleTimer?.cancel();
    super.dispose();
  }

  void _requestSync({
    bool immediate = false,
    String? qrLabel,
    String? qrPayload,
    bool clearQr = false,
  }) {
    if (_holdingDone) return;
    if (!_service.isEnabled) return;

    if (clearQr) {
      _pendingClearQr = true;
      _pendingQrLabel = null;
      _pendingQrPayload = null;
    } else {
      if (qrLabel != null) _pendingQrLabel = qrLabel;
      if (qrPayload != null) _pendingQrPayload = qrPayload;
    }

    _dirty = true;

    if (immediate) {
      _cartIdleTimer?.cancel();
      _kickFlush();
      return;
    }

    // Trailing-only: mientras sigue escaneando, reinicia el timer y no hace IPC.
    _cartIdleTimer?.cancel();
    _cartIdleTimer = Timer(_cartIdleDebounce, _kickFlush);
  }

  void _kickFlush() {
    if (!_dirty || _holdingDone) return;
    if (_syncInFlight) return; // al terminar el sync en vuelo, reintenta
    unawaited(_flushOnce());
  }

  Future<void> _flushOnce() async {
    if (!_dirty || _holdingDone || !mounted) return;
    if (_syncInFlight) return;

    _dirty = false;
    final clearQr = _pendingClearQr;
    if (clearQr) {
      _pendingClearQr = false;
      _pendingQrLabel = null;
      _pendingQrPayload = null;
      CustomerDisplayQrBridge.clear();
    }

    // Bridge = QR real (MP/PVS) + fase de polling; no pisarlo con sync de carrito.
    final qrLabel = clearQr
        ? null
        : (CustomerDisplayQrBridge.label ?? _pendingQrLabel);
    final qrPayload = clearQr
        ? null
        : (CustomerDisplayQrBridge.payload ?? _pendingQrPayload);
    final qrPhase = clearQr
        ? CustomerDisplayQrPhase.none
        : CustomerDisplayQrBridge.phase;
    final qrDetail = clearQr ? null : CustomerDisplayQrBridge.detail;

    final snapshot = _buildSnapshot(
      context.read<CartBloc>().state,
      qrLabel: qrLabel,
      qrPayload: qrPayload,
      qrPhase: qrPhase,
      qrDetail: qrDetail,
      clearQr: clearQr,
    );
    if (snapshot == null || snapshot == _lastSent) {
      // Si llegó otro scan mientras construíamos, ya está _dirty otra vez.
      if (_dirty) _kickFlush();
      return;
    }

    _syncInFlight = true;
    _lastSent = snapshot;
    try {
      // Fire: el await no bloquea el UI del cajero (listener ya volvió).
      await _service.sync(snapshot);
    } catch (e, st) {
      AppLogger.error('CustomerDisplayBinder: sync falló', e, st);
    } finally {
      _syncInFlight = false;
      if (_dirty) {
        // Hubo más scans durante el IPC → un solo sync con el estado actual.
        _cartIdleTimer?.cancel();
        _cartIdleTimer = Timer(_cartIdleDebounce, _kickFlush);
      }
    }
  }

  CustomerDisplaySnapshot? _buildSnapshot(
    CartState state, {
    String? qrLabel,
    String? qrPayload,
    CustomerDisplayQrPhase qrPhase = CustomerDisplayQrPhase.none,
    String? qrDetail,
    bool clearQr = false,
  }) {
    if (state is! CartLoaded) {
      return const CustomerDisplaySnapshot.idle();
    }
    if (!mounted) return null;

    final ui = context.read<UiBloc>().state;
    final confirming =
        ui is UiLoaded && ui.showConfirmationPanel && state.items.isNotEmpty;
    final processing =
        context.read<CheckoutBloc>().state is CheckoutProcessing;

    if (state.items.isEmpty) {
      return const CustomerDisplaySnapshot.idle();
    }

    var snap = CustomerDisplaySnapshot.fromCartLoaded(
      state,
      mode: confirming
          ? CustomerDisplayMode.payment
          : CustomerDisplayMode.cart,
      qrLabel: clearQr ? null : qrLabel,
      qrPayload: clearQr ? null : qrPayload,
      qrPhase: clearQr ? CustomerDisplayQrPhase.none : qrPhase,
      qrDetail: clearQr ? null : qrDetail,
      isProcessing: confirming && processing,
    );
    if (clearQr) {
      snap = snap.copyWith(clearQr: true);
    } else if (qrLabel != null ||
        qrPayload != null ||
        qrDetail != null ||
        qrPhase != CustomerDisplayQrPhase.none) {
      snap = snap.copyWith(
        qrLabel: qrLabel,
        qrPayload: qrPayload,
        qrPhase: qrPhase,
        qrDetail: qrDetail,
      );
    }
    return snap;
  }

  Future<void> _onCheckoutSuccess() async {
    _doneTimer?.cancel();
    _cartIdleTimer?.cancel();
    _holdingDone = true;
    _dirty = false;
    CustomerDisplayQrBridge.clear();
    _pendingQrLabel = null;
    _pendingQrPayload = null;
    _pendingClearQr = false;
    final done = _lastSent.copyWith(
      mode: CustomerDisplayMode.done,
      clearQr: true,
      isProcessing: false,
    );
    _lastSent = done;
    // Done es raro: sí esperamos, fuera del path de escaneo.
    try {
      await _service.sync(done);
    } catch (e, st) {
      AppLogger.error('CustomerDisplayBinder: done sync falló', e, st);
    }
    _doneTimer = Timer(const Duration(seconds: 3), () {
      _holdingDone = false;
      if (!mounted) return;
      _requestSync(immediate: true, clearQr: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CartBloc, CartState>(
          // Solo marca dirty — cero JSON/IPC en el beep.
          listener: (context, state) => _requestSync(),
        ),
        BlocListener<UiBloc, UiState>(
          listenWhen: (prev, next) {
            final p = prev is UiLoaded && prev.showConfirmationPanel;
            final n = next is UiLoaded && next.showConfirmationPanel;
            return p != n;
          },
          listener: (context, state) {
            final confirming =
                state is UiLoaded && state.showConfirmationPanel;
            _requestSync(
              immediate: true,
              clearQr: !confirming,
            );
          },
        ),
        BlocListener<CheckoutBloc, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutSuccess) {
              unawaited(_onCheckoutSuccess());
              return;
            }
            _requestSync(immediate: true);
          },
        ),
      ],
      child: widget.child,
    );
  }
}
