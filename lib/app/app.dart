import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/themes/app_theme.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
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
            return SafeArea(
              child: MaterialApp.router(
                title: 'POS Flutter App',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: mode,
                routerConfig: AppRouter.router,
                debugShowCheckedModeBanner: false,
              ),
            );
          },
        );
      },
    );
  }
}
