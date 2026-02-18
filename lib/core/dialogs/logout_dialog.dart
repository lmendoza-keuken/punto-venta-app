import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_bloc.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_event.dart';
import 'package:punto_venta_app/features/auth/prensetation/bloc/auth_state.dart';
import 'package:punto_venta_app/features/auth/data/datasources/auth_local_datasources.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/injection_container.dart' as di;

Future<void> showLogoutDialog(BuildContext context) async {
  final localDataSource = di.sl<AuthLocalDataSource>();
  final cachedEnterprise = await localDataSource.getCachedEnterprise();
  final cachedEmail = await localDataSource.getCachedEmail();

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String? email;
          int? companyId;
          String? companyName;

          if (cachedEnterprise != null && cachedEmail != null) {
            companyId = cachedEnterprise.id;
            companyName = cachedEnterprise.name;
            email = cachedEmail;
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cerrar Sesión',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.paddingS),
                  Text(
                    '¿Qué deseas hacer?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  const SizedBox(height: AppDimensions.paddingXL),
                  if (email != null && companyId != null) ...[
                    ActionCard(
                      icon: Icons.people_alt,
                      iconColor: Colors.orange,
                      backgroundColor: Colors.orange.withValues(alpha: 0.1),
                      title: 'Cambiar usuario',
                      subtitle: 'Mantener sesión de empresa activa',
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        context.read<CartBloc>().add(ClearCart());
                        context.read<AuthBloc>().add(ChangeCashierRequested());

                        context.go(
                          RoutePaths.credentials,
                          extra: {
                            'email': email,
                            'companyId': companyId,
                            'companyName': companyName ?? 'Empresa',
                          },
                        );
                      },
                    ),
                    const SizedBox(height: AppDimensions.paddingM),
                  ],
                  ActionCard(
                    icon: Icons.exit_to_app,
                    iconColor: Colors.red,
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                    title: 'Cerrar Sesión Completa',
                    subtitle: 'Salir de la aplicación',
                    onTap: () async {
                      await localDataSource.logout();
                      await localDataSource.clearEnterprise();
                      await localDataSource.clearEmail();
                      context.read<CartBloc>().add(ClearCart());
                      context.read<AuthBloc>().add(LogoutRequested());
                      Navigator.of(dialogContext).pop();
                      context.go(RoutePaths.login);
                    },
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingXL,
                        vertical: AppDimensions.paddingM,
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const ActionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.paddingS),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled
                  ? iconColor.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? backgroundColor
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.borderRadiusM),
                ),
                child: Icon(
                  icon,
                  color: enabled ? iconColor : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: enabled ? iconColor : Colors.grey,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.paddingXS),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: enabled
                    ? iconColor.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
