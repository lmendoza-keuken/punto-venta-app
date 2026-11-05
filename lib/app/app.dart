import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';
import 'package:punto_venta_app/core/themes/app_theme.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
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
            return WindowsFullscreenHotkeys(
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
                  // Teclado virtual solo en Windows (POS). Compacto abajo.
                  builder: !kIsWeb && Platform.isWindows
                      ? OnscreenKeyboard.builder(
                          layout: const MobileKeyboardLayout(),
                          // Más ancho que alto para que no cubra toda la pantalla.
                          aspectRatio: 2.6,
                          width: (ctx) {
                            final screen = MediaQuery.sizeOf(ctx).width;
                            return screen * 0.5;
                          },
                          theme: const OnscreenKeyboardThemeData(
                            margin: EdgeInsets.only(bottom: 12),
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
