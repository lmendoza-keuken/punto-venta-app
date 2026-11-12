import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:punto_venta_app/app/routes/app_router.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/utils/navigator_popup.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';

/// Evita que Android cierre la Activity cuando, tras cerrar un dialog, el
/// siguiente back no llega al [PopScope] del shell (go_router nested navigator).
///
/// Se registra como [WidgetsBindingObserver] y, si nadie consumió el back,
/// maneja popups / POS / "Salir" y siempre retorna `true` dentro del shell.
class SystemBackGuard extends StatefulWidget {
  final Widget child;

  const SystemBackGuard({super.key, required this.child});

  @override
  State<SystemBackGuard> createState() => _SystemBackGuardState();
}

class _SystemBackGuardState extends State<SystemBackGuard>
    with WidgetsBindingObserver {
  DateTime? _consumedAt;
  bool _exitDialogOpen = false;

  static const _consumeWindow = Duration(milliseconds: 700);

  static const _authRoutes = {
    RoutePaths.splash,
    RoutePaths.login,
    RoutePaths.companySelection,
    RoutePaths.credentials,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _justConsumed =>
      _consumedAt != null &&
      DateTime.now().difference(_consumedAt!) < _consumeWindow;

  void _markConsumed() => _consumedAt = DateTime.now();

  String get _location {
    try {
      return AppRouter.router.state.uri.path;
    } catch (_) {
      return RoutePaths.splash;
    }
  }

  bool get _isInShell => !_authRoutes.contains(_location);

  @override
  Future<bool> didPopRoute() async {
    // Fuera del shell (login/splash): dejar el comportamiento normal.
    if (!_isInShell) return false;

    // Tras cerrar un dialog, a veces llega un segundo popRoute del mismo gesto.
    if (_justConsumed) {
      _consumedAt = null;
      return true;
    }

    // 1) Cerrar dialogs/modals en root o shell navigator.
    final rootNav = AppRouter.navigatorKey.currentState;
    if (rootNav != null && popNavigatorPopup(rootNav)) {
      _markConsumed();
      return true;
    }

    final shellNav = AppRouter.shellNavigatorKey.currentState;
    if (shellNav != null && popNavigatorPopup(shellNav)) {
      _markConsumed();
      return true;
    }

    // 2) Otras pantallas del shell → volver al POS.
    if (_location != RoutePaths.pos) {
      _markConsumed();
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ctx.go(RoutePaths.pos);
      }
      return true;
    }

    // 3) POS: cerrar confirmation panel si está abierto.
    final posContext =
        AppRouter.shellNavigatorKey.currentContext ??
        AppRouter.navigatorKey.currentContext;
    if (posContext != null && posContext.mounted) {
      try {
        final uiBloc = posContext.read<UiBloc>();
        final uiState = uiBloc.state;
        if (uiState is UiLoaded && uiState.showConfirmationPanel) {
          _markConsumed();
          uiBloc.add(CloseConfirmationPanel());
          return true;
        }
      } catch (_) {
        // UiBloc no disponible en este context.
      }
    }

    // 4) Mostrar diálogo de salir (nunca SystemNavigator.pop implícito).
    if (_exitDialogOpen) {
      return true;
    }

    final dialogContext = posContext;
    if (dialogContext == null || !dialogContext.mounted) {
      return true;
    }

    _markConsumed();
    _exitDialogOpen = true;
    await showDialog<void>(
      barrierDismissible: false,
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Salir'),
        content: const Text('¿Seguro que quieres salir de la app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    _markConsumed();
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
