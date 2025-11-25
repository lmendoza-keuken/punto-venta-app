import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/auth/prensetation/pages/login_page.dart';
import 'package:punto_venta_app/features/pos/presentation/pages/pos_main_page.dart';
import 'package:punto_venta_app/features/splash/presentation/pages/splash_page.dart';
import 'package:punto_venta_app/features/stock/presentation/pages/stock_management_page.dart';
import 'route_paths.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPage();
        },
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: RoutePaths.pos,
        builder: (BuildContext context, GoRouterState state) {
          return const PosMainPage();
        },
      ),
      GoRoute(
        path: RoutePaths.stock,
        builder: (BuildContext context, GoRouterState state) {
          return const StockManagementPage();
        },
      ),
    ],
  );
}
