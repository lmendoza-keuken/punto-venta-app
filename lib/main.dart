import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
import 'package:punto_venta_app/core/utils/app_logger.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/customer_display/data/windows_customer_display_service.dart';
import 'package:punto_venta_app/features/customer_display/presentation/customer_display_window_bootstrap.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/payment_methods/payment_methods_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/pdv_config/pdv_config_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/printer/printer_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/reports/reports_bloc.dart';
import 'package:punto_venta_app/firebase_options.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'features/customer_display/presentation/android_secondary_entry.dart';
import 'features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'features/pos/presentation/bloc/product/product_bloc.dart';
import 'features/pos/presentation/bloc/saved_orders/saved_orders_bloc.dart';
import 'features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'features/splash/presentation/bloc/splash_bloc.dart';
import 'injection_container.dart' as di;

/// Entry-point fijo requerido por presentation_displays (Android Presentation).
@pragma('vm:entry-point')
void secondaryDisplayMain() {
  runAndroidSecondaryDisplay();
}

void main(List<String> args) {
  runZonedGuarded(() async {
    // Probe síncrono ANTES de Flutter binding: si el proceso muere antes
    // del logger, este archivo en Temp confirma que Dart llegó a main().
    AppLogger.bootProbe('main() entered args=${args.length}');

    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.bootProbe('WidgetsFlutterBinding.ensureInitialized ok');

    // Logger lo antes posible: window_manager / multi_window pueden tumbar
    // el proceso sin dejar rastro si el log inicia después.
    await AppLogger.init();
    _installGlobalErrorHandlers();
    AppLogger.info('Boot stage=logger_ready');

    // Subventana Windows PRIMERO: no PackageInfo/Firebase/window main.
    // Si el engine secundario sigue el path del cajero, puede tumbar todo.
    AppLogger.info('Boot stage=customer_display_check start');
    if (await _launchCustomerDisplayIfNeeded(args)) {
      AppLogger.info('Boot stage=customer_display_check is_secondary=true');
      return;
    }
    AppLogger.info('Boot stage=customer_display_check is_secondary=false');

    AppLogger.info(
      'Arranque: platform=$defaultTargetPlatform debug=$kDebugMode '
      'args=$args',
    );
    await _logPackageInfo();
    _logEnvironment();

    AppLogger.info('Boot stage=window_manager start');
    await _configureWindowsMainWindow();
    AppLogger.info('Boot stage=window_manager done');

    // Layout is width-driven (LayoutSpec). Android may rotate to portrait;
    // desktop keeps landscape as the preferred default without duplicating UI.
    AppLogger.info('Boot stage=orientations start');
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    AppLogger.info('Boot stage=orientations done');

    AppLogger.info('Boot stage=di_init start');
    await di.init();
    AppLogger.info('Boot stage=di_init done');

    AppLogger.info('Boot stage=firebase_init start');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info(
      'Boot stage=firebase_init done proyecto=${Firebase.app().options.projectId}',
    );
    _configureFirestore();
    await _signInAnonymously();

    AppLogger.info('Boot stage=runApp');
    runApp(const MyApp());
    AppLogger.info('Boot stage=runApp scheduled');
  }, (error, stackTrace) {
    AppLogger.bootProbe('ZONE ERROR: $error');
    AppLogger.error('Error no capturado (zona)', error, stackTrace);
  });
}

Future<void> _logPackageInfo() async {
  try {
    final info = await PackageInfo.fromPlatform();
    AppLogger.info(
      'PackageInfo version=${info.version} build=${info.buildNumber} '
      'packageName=${info.packageName} appName=${info.appName}',
    );
  } catch (e, stackTrace) {
    AppLogger.error('PackageInfo falló', e, stackTrace);
  }
}

/// Detecta si este isolate es la ventana de cliente (desktop_multi_window 0.3 / legacy).
Future<bool> _launchCustomerDisplayIfNeeded(List<String> args) async {
  if (kIsWeb || !Platform.isWindows) return false;

  // Legacy CLI: ['multi_window', windowId, argumentJson]
  if (args.isNotEmpty && args.first == 'multi_window') {
    AppLogger.info('CustomerDisplay: legacy multi_window args');
    final argumentJson = args.length > 2 ? args[2] : '';
    await runCustomerDisplayWindow(argumentJson);
    return true;
  }

  try {
    AppLogger.bootProbe('CustomerDisplay: fromCurrentEngine...');
    AppLogger.info('CustomerDisplay: WindowController.fromCurrentEngine...');
    final controller = await WindowController.fromCurrentEngine();
    final raw = controller.arguments;
    AppLogger.bootProbe('CustomerDisplay: argsLen=${raw.length}');
    AppLogger.info(
      'CustomerDisplay: engine argsLen=${raw.length} '
      'preview=${raw.length > 120 ? '${raw.substring(0, 120)}...' : raw}',
    );
    if (raw.isEmpty) return false;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    if (map['type'] != kCustomerDisplayWindowArg) {
      AppLogger.info('CustomerDisplay: type!=customer_display -> main window');
      return false;
    }
    AppLogger.info('CustomerDisplay: launching secondary window');
    AppLogger.bootProbe('CustomerDisplay: runCustomerDisplayWindow');
    await runCustomerDisplayWindow(raw);
    return true;
  } catch (e, stackTrace) {
    AppLogger.bootProbe('CustomerDisplay check error: $e');
    AppLogger.warn('CustomerDisplay: fromCurrentEngine no-op ($e)');
    AppLogger.error('CustomerDisplay check detail', e, stackTrace);
    return false;
  }
}

Future<void> _configureWindowsMainWindow() async {
  if (!Platform.isWindows) return;

  try {
    AppLogger.info('window_manager.ensureInitialized...');
    await windowManager.ensureInitialized();
    AppLogger.info('window_manager.waitUntilReadyToShow...');
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        fullScreen: false,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      ),
      () async {
        try {
          // Sin setFullScreen: congela o tumba con multi_window.
          AppLogger.info('window_manager ready callback: maximize');
          await windowManager.maximize();
          AppLogger.info('window_manager ready callback: show');
          await windowManager.show();
          AppLogger.info('window_manager ready callback: focus');
          await windowManager.focus();
          AppLogger.info('window_manager ready callback: done');
        } catch (e, stackTrace) {
          AppLogger.error('window_manager ready callback falló', e, stackTrace);
        }
      },
    );
  } catch (e, stackTrace) {
    AppLogger.error('window_manager configure falló', e, stackTrace);
    rethrow;
  }
}

/// Windows puede matar el proceso al paginar el ejecutable si éste vive en una
/// unidad de red, un disco extraíble o una carpeta sincronizada (OneDrive).
void _logEnvironment() {
  try {
    final exePath = Platform.resolvedExecutable;
    final isUnc = exePath.startsWith(r'\\');
    final env = Platform.environment;

    AppLogger.info('SO: ${Platform.operatingSystemVersion}');
    AppLogger.info('Ejecutable: $exePath');
    AppLogger.info(
      'Unidad: ${exePath.length >= 2 ? exePath.substring(0, 2) : '?'} '
      'rutaUNC=$isUnc',
    );
    AppLogger.info('OneDrive env=${env['OneDrive'] ?? '(no definido)'}');
    AppLogger.info('Temp: ${Directory.systemTemp.path}');
    AppLogger.info(
      'LOCALAPPDATA=${env['LOCALAPPDATA'] ?? '(no)'} '
      'USERNAME=${env['USERNAME'] ?? '(no)'}',
    );

    final exeDir = File(exePath).parent;
    final entries = exeDir.listSync();
    AppLogger.info('Carpeta del ejecutable legible, ${entries.length} entradas');
    for (final entity in entries) {
      final name = entity.uri.pathSegments.isNotEmpty
          ? entity.uri.pathSegments.last
          : entity.path;
      final kind = entity is Directory ? 'dir' : 'file';
      var size = '';
      if (entity is File) {
        try {
          size = ' bytes=${entity.lengthSync()}';
        } catch (_) {}
      }
      AppLogger.info('  install/$kind $name$size');
    }
  } catch (e, stackTrace) {
    AppLogger.error('No se pudo inspeccionar el entorno', e, stackTrace);
  }
}

void _installGlobalErrorHandlers() {
  FlutterError.onError = (details) {
    AppLogger.error(
      'FlutterError: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('PlatformDispatcher.onError', error, stack);
    return true;
  };

  ErrorWidget.builder = (details) {
    AppLogger.error('ErrorWidget', details.exception, details.stack);
    return Material(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            'Error:\n${details.exceptionAsString()}\n\nLog: ${AppLogger.logPath}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  };
}

/// En Windows la caché local (LevelDB) del SDK nativo de Firestore puede
/// tumbar el proceso sin dejar error en Dart, según permisos y ruta del perfil.
const bool _firestorePersistenceOnWindows =
    bool.fromEnvironment('FIRESTORE_PERSISTENCE', defaultValue: false);

void _configureFirestore() {
  try {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: _firestorePersistenceOnWindows,
      );
      AppLogger.info(
        'Firestore settings: persistenceEnabled=$_firestorePersistenceOnWindows',
      );
    }
  } catch (e, stackTrace) {
    AppLogger.error(
      'No se pudieron aplicar los settings de Firestore',
      e,
      stackTrace,
    );
  }
}

Future<void> _signInAnonymously() async {
  try {
    AppLogger.info('FirebaseAuth.signInAnonymously...');
    await FirebaseAuth.instance.signInAnonymously();
    AppLogger.info(
      'FirebaseAuth anónimo OK uid=${FirebaseAuth.instance.currentUser?.uid}',
    );
  } catch (e, stackTrace) {
    AppLogger.error('Error de autenticación anónima', e, stackTrace);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => di.sl<SplashBloc>()),
        BlocProvider(create: (_) => di.sl<AuthBloc>()),
        BlocProvider(create: (_) => di.sl<ProductBloc>()),
        BlocProvider(create: (_) => di.sl<CartBloc>()),
        BlocProvider(create: (_) => di.sl<UiBloc>()),
        BlocProvider(create: (_) => di.sl<SavedOrdersBloc>()),
        BlocProvider(create: (_) => di.sl<ReportsBloc>()),
        BlocProvider(create: (_) => di.sl<ClientsBloc>()),
        BlocProvider(create: (_) => di.sl<PrinterBloc>()),
        BlocProvider(create: (_) => di.sl<PaymentMethodsBloc>()),
        BlocProvider(create: (_) => di.sl<PdvConfigBloc>()),
        BlocProvider(create: (_) => di.sl<CheckoutBloc>()),
      ],
      child: const PosApp(),
    );
  }
}
