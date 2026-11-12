import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';

/// Intercepta el back del sistema **dentro** del navigator del [ShellRoute].
///
/// Debe envolver cada página hija del shell (no el chrome del shell): si el
/// [PopScope] queda fuera del navigator anidado, Android puede cerrar la app
/// sin notificar a Flutter (predictive back / frameworkHandlesBack).
class ShellPopScope extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (!isRootShellPage) {
          context.go(RoutePaths.pos);
          return;
        }

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
        );
      },
      child: child,
    );
  }
}
