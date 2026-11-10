import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/core/widgets/windows_fullscreen_hotkeys.dart';
import 'package:punto_venta_app/features/customer_display/data/windows_customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_app.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_host.dart';
import 'package:window_manager/window_manager.dart';

final GlobalKey<CustomerDisplayHostState> customerDisplayHostKey =
    GlobalKey<CustomerDisplayHostState>();

/// Arranque de la subventana Windows (engine separado).
///
/// No usar [WindowManager.setFullScreen] ni [WindowManager.setAsFrameless]:
/// con `desktop_multi_window` han tumado el proceso (principal + secundaria).
/// Ocupamos el frame del 2º monitor con bounds + titleBar hidden.
Future<void> runCustomerDisplayWindow(String argumentsJson) async {
  AppLogger.bootProbe('customer_display window bootstrap start');
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('CustomerDisplay window: ensureInitialized ok');

  Map<String, dynamic> args = {};
  try {
    if (argumentsJson.isNotEmpty) {
      args = jsonDecode(argumentsJson) as Map<String, dynamic>;
    }
  } catch (e, st) {
    AppLogger.error('CustomerDisplay window: args JSON inválido', e, st);
  }

  final frameMap = args['frame'] as Map<String, dynamic>?;
  final left = (frameMap?['left'] as num?)?.toDouble() ?? 100;
  final top = (frameMap?['top'] as num?)?.toDouble() ?? 100;
  final width = (frameMap?['width'] as num?)?.toDouble() ?? 900;
  final height = (frameMap?['height'] as num?)?.toDouble() ?? 700;
  final targetBounds = Rect.fromLTWH(left, top, width, height);
  AppLogger.info('CustomerDisplay window: targetBounds=$targetBounds');

  try {
    AppLogger.info('CustomerDisplay window: windowManager.ensureInitialized...');
    await windowManager.ensureInitialized();
    AppLogger.info('CustomerDisplay window: WindowController.fromCurrentEngine...');
    final windowController = await WindowController.fromCurrentEngine();
    await windowController.setWindowMethodHandler((call) async {
      switch (call.method) {
        case kCustomerDisplaySyncMethod:
          customerDisplayHostKey.currentState?.applyPayload(call.arguments);
          return true;
        case 'window_close':
          AppLogger.info('CustomerDisplay window: method window_close');
          try {
            await windowManager.setPreventClose(false);
          } catch (_) {}
          await windowManager.close();
          return true;
        default:
          return null;
      }
    });
    AppLogger.info('CustomerDisplay window: method handler registrado');

    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        fullScreen: false,
        skipTaskbar: true,
        titleBarStyle: TitleBarStyle.hidden,
        size: Size(width, height),
        center: false,
      ),
      () async {
        try {
          AppLogger.info('CustomerDisplay window: ready → setBounds');
          await windowManager.setBounds(targetBounds);
          await windowManager.setTitle('Pantalla cliente');
          await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
          await windowManager.show();
          await windowManager.focus();
          AppLogger.info(
            'CustomerDisplay window: visible en frame=$targetBounds '
            '(bounds, sin setFullScreen/setAsFrameless)',
          );
        } catch (e, st) {
          AppLogger.error(
            'CustomerDisplay window: ready callback falló',
            e,
            st,
          );
        }
      },
    );
  } catch (e, st) {
    AppLogger.error('CustomerDisplay window: setup falló', e, st);
    rethrow;
  }

  AppLogger.info('CustomerDisplay window: runApp');
  runApp(
    WindowsFullscreenHotkeys(
      windowedBounds: targetBounds,
      preferBoundsFullscreen: true,
      child: CustomerDisplayApp(hostKey: customerDisplayHostKey),
    ),
  );
  AppLogger.bootProbe('customer_display window runApp scheduled');
}
