import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/utils/navigator_popup.dart';

/// Intercepta el back del sistema **dentro** del navigator del [ShellRoute].
///
/// Debe envolver cada página hija del shell (no el chrome del shell): si el
/// [PopScope] queda fuera del navigator anidado, Android puede cerrar la app
/// sin notificar a Flutter (predictive back / frameworkHandlesBack).
class ShellPopScope extends StatefulWidget {
  final Widget child;

  /// `true` en la pantalla principal del shell (POS): muestra diálogo de salir.
  /// `false` en el resto: navega al POS.
  final bool isRootShellPage;

  const ShellPopScope({
    super.key,
    required this.child,
    this.isRootShellPage = false,
  });

  @override
  State<ShellPopScope> createState() => _ShellPopScopeState();
}

class _ShellPopScopeState extends State<ShellPopScope> {
  DateTime? _backConsumedAt;
  static const _backConsumeWindow = Duration(milliseconds: 600);

  bool get _backWasJustConsumed =>
      _backConsumedAt != null &&
      DateTime.now().difference(_backConsumedAt!) < _backConsumeWindow;

  void _markBackConsumed() {
    _backConsumedAt = DateTime.now();
  }

  void _handleBack(BuildContext context) {
    if (_backWasJustConsumed) {
      _backConsumedAt = null;
      return;
    }

    // Solo cerrar dialogs/modals — nunca pop de rutas del shell/go_router.
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (popNavigatorPopup(rootNavigator)) {
      _markBackConsumed();
      return;
    }

    final localNavigator = Navigator.of(context);
    if (popNavigatorPopup(localNavigator)) {
      _markBackConsumed();
      return;
    }

    if (!widget.isRootShellPage) {
      _markBackConsumed();
      context.go(RoutePaths.pos);
      return;
    }

    _markBackConsumed();
    showDialog<void>(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salir'),
        content: const Text('¿Seguro que quieres salir de la app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Salir'),
          ),
        ],
      ),
    ).whenComplete(_markBackConsumed);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: widget.child,
    );
  }
}
