import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';
import 'package:punto_venta_app/features/auth/prensetation/widgets/login_form.dart';
import 'package:punto_venta_app/features/auth/prensetation/widgets/login_header.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final localDs = di.sl<AuthLocalDataSource>();
      final enterprise = await localDs.getCachedEnterprise();
      final email = await localDs.getCachedEmail();

      if (!context.mounted) return;

      if (enterprise != null && email != null) {
        context.go(
          RoutePaths.credentials,
          extra: {
            'email': email,
            'companyId': enterprise.id,
            'companyName': enterprise.name,
          },
        );
      }
    });

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(RoutePaths.pos);
        } else if (state is AuthCompanySelected) {
          context.go(
            RoutePaths.credentials,
            extra: {
              'email': state.email,
              'companyId': state.companyId,
              'companyName': state.companyName,
            },
          );
        } else if (state is AuthCompanySelectionRequired) {
          context.go(RoutePaths.companySelection);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: const Card(
                        elevation: 8,
                        child: Padding(
                          padding: EdgeInsets.all(AppDimensions.paddingL),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LoginHeader(),
                              SizedBox(height: AppDimensions.paddingL),
                              LoginForm(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  children: [
                    Text(
                      AppStrings.keukenName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text(
                      AppStrings.keukenDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.selectClientButton,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
