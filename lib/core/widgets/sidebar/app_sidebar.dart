import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/dialogs/logout_dialog.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
import 'package:punto_venta_app/core/widgets/sidebar/sidebar_item.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/settings_dialog.dart';

/// Sidebar navigation component inspired by modern POS designs
/// Provides quick access to main app sections
class AppSidebar extends StatefulWidget {
  final String currentRoute;
  final bool isAdmin;
  final VoidCallback? onLogout;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onMessagesPressed;
  final VoidCallback? onHistoryPressed;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    this.isAdmin = false,
    this.onLogout,
    this.onSettingsPressed,
    this.onNotificationsPressed,
    this.onMessagesPressed,
    this.onHistoryPressed,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _isSettingsDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark;
        final sidebarBg = isDark
            ? AppColors.sidebarDarkBackground
            : AppColors.sidebarLightBackground;
        final sidebarSurface =
            isDark ? AppColors.sidebarDarkSurface : AppColors.sidebarLightSurface;
        final sidebarDivider =
            isDark ? AppColors.sidebarDarkDivider : AppColors.sidebarLightDivider;

        return Container(
          width: 80,
          decoration: BoxDecoration(
            color: sidebarBg,
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Logo
              _buildLogo(),
              const SizedBox(height: 24),

              // Home - POS
              _buildNavItem(
                context,
                isSelected: widget.currentRoute == RoutePaths.pos,
                isDark: isDark,
                sidebarSurface: sidebarSurface,
                child: SidebarItem(
                  icon: Icons.home_rounded,
                  isHighlighted: widget.currentRoute == RoutePaths.pos,
                  tooltip: 'Punto de Venta',
                  onTap: () => _navigateTo(context, RoutePaths.pos),
                ),
              ),

              const SizedBox(height: 8),

              // Navigation items
              Column(
                children: [
                  // History / Reports
                  _buildNavItem(
                    context,
                    isSelected: widget.currentRoute == RoutePaths.reports,
                    isDark: isDark,
                    sidebarSurface: sidebarSurface,
                    child: SidebarItem(
                      icon: Icons.history_rounded,
                      isHighlighted: widget.currentRoute == RoutePaths.reports,
                      tooltip: 'Historial',
                      onTap: widget.onHistoryPressed ??
                          () => _navigateTo(context, RoutePaths.reports),
                    ),
                  ),

                  // Stock / Inventory
                  _buildNavItem(
                    context,
                    isSelected: widget.currentRoute == RoutePaths.stock,
                    isDark: isDark,
                    sidebarSurface: sidebarSurface,
                    child: SidebarItem(
                      icon: Icons.inventory_2_rounded,
                      isHighlighted: widget.currentRoute == RoutePaths.stock,
                      tooltip: 'Inventario',
                      onTap: () => _navigateTo(context, RoutePaths.stock),
                    ),
                  ),

                  // Notifications
                  _buildNavItem(
                    context,
                    isSelected: false,
                    isDark: isDark,
                    sidebarSurface: sidebarSurface,
                    child: SidebarItem(
                      icon: Icons.notifications_none_rounded,
                      tooltip: 'Notificaciones',
                      onTap: widget.onNotificationsPressed,
                    ),
                  ),
                ],
              ),

              // Spacer para empujar el bottom section al final
              const Spacer(),

              // Bottom section
              Divider(
                color: sidebarDivider,
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              const SizedBox(height: 8),

              // Settings (solo si es administrador)
              if (widget.isAdmin)
                _buildNavItem(
                  context,
                  isSelected: _isSettingsDialogOpen,
                  isDark: isDark,
                  sidebarSurface: sidebarSurface,
                  child: SidebarItem(
                    icon: Icons.settings_outlined,
                    isHighlighted: _isSettingsDialogOpen,
                    tooltip: 'Configuración',
                    onTap: widget.onSettingsPressed ??
                        () async {
                          setState(() => _isSettingsDialogOpen = true);
                          await showDialog(
                            context: context,
                            builder: (context) => BlocProvider.value(
                              value: context.read<ClientsBloc>(),
                              child: const SettingsDialog(),
                            ),
                          );
                          setState(() => _isSettingsDialogOpen = false);
                        },
                  ),
                ),

              _buildNavItem(
                context,
                isSelected: false,
                isDark: isDark,
                sidebarSurface: sidebarSurface,
                child: SidebarItem(
                  icon: Icons.logout_rounded,
                  tooltip: 'Cerrar sesión',
                  onTap: () => showLogoutDialog(context),
                ),
              ),

              // Theme switch
              _buildThemeToggle(
                context,
                isDark: mode == ThemeMode.dark,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return SvgPicture.asset(
      'assets/icons/logo.svg',
      width: 48,
      height: 48,
    );
  }

  Widget _buildThemeToggle(BuildContext context, {required bool isDark}) {
    final iconColor =
        isDark ? AppColors.sidebarAccent : AppColors.sidebarIconInactive;

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            size: 18,
            color: iconColor,
          ),
          Transform.scale(
            scale: 0.7,
            child: Switch.adaptive(
              value: isDark,
              onChanged: (_) {
                context.read<ThemeCubit>().toggleTheme();
              },
              activeColor: AppColors.sidebarAccent,
              inactiveThumbColor: AppColors.sidebarIconInactive,
              inactiveTrackColor: AppColors.sidebarSwitchTrack,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required bool isSelected,
    required Widget child,
    required bool isDark,
    required Color sidebarSurface,
  }) {
    return SizedBox(
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          if (isSelected)
            Positioned(
              left: 8,
              right: -16,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: sidebarSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    if (widget.currentRoute != route) {
      context.go(route);
    }
  }
}
