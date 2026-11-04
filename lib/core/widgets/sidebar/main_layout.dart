import 'package:flutter/material.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/widgets/sidebar/app_sidebar.dart';
import 'package:punto_venta_app/core/widgets/sidebar/main_scaffold_scope.dart';

/// Main layout wrapper that includes the sidebar navigation.
/// Expanded/medium: permanent rail. Compact: drawer via [MainScaffoldScope].
class MainLayout extends StatefulWidget {
  final String currentRoute;
  final bool isAdmin;
  final Widget child;
  final VoidCallback? onLogout;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onMessagesPressed;
  final VoidCallback? onHistoryPressed;

  const MainLayout({
    super.key,
    required this.currentRoute,
    this.isAdmin = false,
    required this.child,
    this.onLogout,
    this.onSettingsPressed,
    this.onNotificationsPressed,
    this.onMessagesPressed,
    this.onHistoryPressed,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spec = LayoutSpec.fromWidth(constraints.maxWidth);
        final sidebar = AppSidebar(
          currentRoute: widget.currentRoute,
          isAdmin: widget.isAdmin,
          asDrawer: !spec.useNavigationRail,
          onLogout: widget.onLogout,
          onSettingsPressed: widget.onSettingsPressed,
          onNotificationsPressed: widget.onNotificationsPressed,
          onMessagesPressed: widget.onMessagesPressed,
          onHistoryPressed: widget.onHistoryPressed,
        );

        if (spec.useNavigationRail) {
          return Material(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sidebar,
                Expanded(child: widget.child),
              ],
            ),
          );
        }

        final isPos = widget.currentRoute == RoutePaths.pos;

        return MainScaffoldScope(
          scaffoldKey: _scaffoldKey,
          child: Scaffold(
            key: _scaffoldKey,
            drawer: Drawer(
              width: AppDimensions.sidebarDrawerWidth,
              child: sidebar,
            ),
            // POS has its own menu in PosAppBar; other routes get a compact bar.
            appBar: isPos
                ? null
                : AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    title: const Text('Menú'),
                    toolbarHeight: 48,
                  ),
            body: widget.child,
          ),
        );
      },
    );
  }
}
