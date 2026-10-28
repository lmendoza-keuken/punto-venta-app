import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

/// Engancha el POS con [CustomerDisplayService]: start/stop + sync de estados.
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
  late final CustomerDisplayService _service;
  Timer? _doneTimer;
  bool _holdingDone = false;
  CustomerDisplaySnapshot _lastCart = const CustomerDisplaySnapshot.idle();

  @override
  void initState() {
    super.initState();
    _service = di.sl<CustomerDisplayService>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      if (!_service.isEnabled) return;
      final available = await _service.isAvailable();
      if (!available && defaultTargetPlatform == TargetPlatform.android) {
        AppLogger.info('CustomerDisplayBinder: Android sin 2ª pantalla');
        return;
      }
      await _service.start();
      if (!mounted) return;
      await _pushFromCart(context.read<CartBloc>().state);
    } catch (e, st) {
      AppLogger.error('CustomerDisplayBinder: bootstrap falló', e, st);
    }
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    unawaited(_service.stop());
    super.dispose();
  }

  Future<void> _pushFromCart(CartState state) async {
    if (_holdingDone) return;
    if (state is! CartLoaded) {
      _lastCart = const CustomerDisplaySnapshot.idle();
      await _service.sync(_lastCart);
      return;
    }

    final ui = context.read<UiBloc>().state;
    final confirming =
        ui is UiLoaded && ui.showConfirmationPanel && state.items.isNotEmpty;

    if (state.items.isEmpty) {
      _lastCart = const CustomerDisplaySnapshot.idle();
    } else {
      _lastCart = CustomerDisplaySnapshot.fromCartLoaded(
        state,
        mode: confirming
            ? CustomerDisplayMode.payment
            : CustomerDisplayMode.cart,
      );
    }
    await _service.sync(_lastCart);
  }

  Future<void> _onCheckoutSuccess() async {
    _doneTimer?.cancel();
    _holdingDone = true;
    final done = _lastCart.copyWith(mode: CustomerDisplayMode.done);
    await _service.sync(done);
    _doneTimer = Timer(const Duration(seconds: 3), () async {
      _holdingDone = false;
      if (!mounted) return;
      await _pushFromCart(context.read<CartBloc>().state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CartBloc, CartState>(
          listener: (context, state) => unawaited(_pushFromCart(state)),
        ),
        BlocListener<UiBloc, UiState>(
          listenWhen: (prev, next) {
            final p = prev is UiLoaded && prev.showConfirmationPanel;
            final n = next is UiLoaded && next.showConfirmationPanel;
            return p != n;
          },
          listener: (context, state) =>
              unawaited(_pushFromCart(context.read<CartBloc>().state)),
        ),
        BlocListener<CheckoutBloc, CheckoutState>(
          listener: (context, state) {
            if (state is CheckoutSuccess) {
              unawaited(_onCheckoutSuccess());
            }
          },
        ),
      ],
      child: widget.child,
    );
  }
}
