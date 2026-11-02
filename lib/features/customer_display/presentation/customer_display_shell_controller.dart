import 'dart:async';

import 'package:flutter/material.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_advertising.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

/// Mantiene viva la pantalla cliente mientras hay sesión (shell autenticado).
class CustomerDisplayShellController extends StatefulWidget {
  const CustomerDisplayShellController({
    super.key,
    required this.currentRoute,
    required this.child,
  });

  final String currentRoute;
  final Widget child;

  @override
  State<CustomerDisplayShellController> createState() =>
      _CustomerDisplayShellControllerState();
}

class _CustomerDisplayShellControllerState
    extends State<CustomerDisplayShellController> {
  late final CustomerDisplayService _service;
  String? _lastRoute;

  @override
  void initState() {
    super.initState();
    _service = di.sl<CustomerDisplayService>();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _onRoute(widget.currentRoute));
  }

  @override
  void didUpdateWidget(covariant CustomerDisplayShellController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _onRoute(widget.currentRoute);
    }
  }

  @override
  void dispose() {
    unawaited(_service.stop());
    super.dispose();
  }

  Future<void> _onRoute(String route) async {
    if (_lastRoute == route) return;
    _lastRoute = route;

    try {
      if (!_service.isEnabled) return;

      final available = await _service.isAvailable();
      if (!available) return;

      await _service.start();

      final onPos =
          route == RoutePaths.pos || route.startsWith('${RoutePaths.pos}/');
      if (!onPos) {
        if (!mounted) return;
        final snapshot = buildCustomerDisplayAdvertisingSnapshot(context);
        await _service.sync(snapshot);
        AppLogger.info(
          'CustomerDisplayShell: fuera de POS → publicidad '
          '(${snapshot.adProducts.length} ofertas) ($route)',
        );
      }
    } catch (e, st) {
      AppLogger.error('CustomerDisplayShell: fallo en ruta $route', e, st);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
