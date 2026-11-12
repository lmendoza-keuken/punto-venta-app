import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:punto_venta_app/core/themes/app_theme.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
import 'package:punto_venta_app/core/widgets/system_back_guard.dart';
import 'package:punto_venta_app/core/widgets/windows_fullscreen_hotkeys.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';
import 'routes/app_router.dart';

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            // SystemBackGuard se registra ANTES que el Router del MaterialApp,
            // así si tras cerrar un dialog el Router no consume el back,
            // el guard lo atrapa y evita SystemNavigator.pop() (salida de la app).
            return SystemBackGuard(
              child: WindowsFullscreenHotkeys(
                child: SafeArea(
                  child: MaterialApp.router(
                    title: 'POS Flutter App',
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: mode,
                    routerConfig: AppRouter.router,
                    debugShowCheckedModeBanner: false,
                    locale: const Locale('es', 'AR'),
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    supportedLocales: const [
                      Locale('es', 'AR'),
                      Locale('en', 'US'),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
