import 'package:flutter/material.dart';

/// Exposes drawer open/close for compact [MainLayout] shells.
class MainScaffoldScope extends InheritedWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const MainScaffoldScope({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  static MainScaffoldScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainScaffoldScope>();
  }

  static MainScaffoldScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'MainScaffoldScope not found in context');
    return scope!;
  }

  void openDrawer() {
    scaffoldKey.currentState?.openDrawer();
  }

  void closeDrawer() {
    scaffoldKey.currentState?.closeDrawer();
  }

  @override
  bool updateShouldNotify(MainScaffoldScope oldWidget) {
    return scaffoldKey != oldWidget.scaffoldKey;
  }
}
