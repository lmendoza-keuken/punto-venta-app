import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/customer_display/data/windows_customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_app.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_host.dart';
import 'package:window_manager/window_manager.dart';

final GlobalKey<CustomerDisplayHostState> customerDisplayHostKey =
    GlobalKey<CustomerDisplayHostState>();

/// Arranque de la subventana Windows (engine separado).
Future<void> runCustomerDisplayWindow(String argumentsJson) async {
  WidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> args = {};
  try {
    if (argumentsJson.isNotEmpty) {
      args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    }
  } catch (_) {}

  final frameMap = args['frame'] as Map<String, dynamic>?;
  final fullscreen = args['fullscreen'] == true;
  final left = (frameMap?['left'] as num?)?.toDouble() ?? 100;
  final top = (frameMap?['top'] as num?)?.toDouble() ?? 100;
  final width = (frameMap?['width'] as num?)?.toDouble() ?? 900;
  final height = (frameMap?['height'] as num?)?.toDouble() ?? 700;

  await windowManager.ensureInitialized();

  final windowController = await WindowController.fromCurrentEngine();
  await windowController.setWindowMethodHandler((call) async {
    switch (call.method) {
      case kCustomerDisplaySyncMethod:
        customerDisplayHostKey.currentState?.applyPayload(call.arguments);
        return true;
      case 'window_close':
        await windowManager.close();
        return true;
      default:
        return null;
    }
  });

  await windowManager.waitUntilReadyToShow(
    WindowOptions(
      fullScreen: fullscreen,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      size: Size(width, height),
    ),
    () async {
      if (fullscreen) {
        await windowManager.setFullScreen(true);
      } else {
        await windowManager.setBounds(
          Rect.fromLTWH(left, top, width, height),
        );
      }
      await windowManager.setTitle('Pantalla cliente');
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(CustomerDisplayApp(hostKey: customerDisplayHostKey));
}
