import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:punto_venta_app/app/routes/route_paths.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/dialogs/logout_dialog.dart';
import 'package:punto_venta_app/core/themes/theme_cubit.dart';
import 'package:punto_venta_app/core/widgets/sidebar/main_scaffold_scope.dart';
import 'package:punto_venta_app/core/widgets/sidebar/sidebar_item.dart';
import 'package:punto_venta_app/features/pos/domain/entities/client.dart';
import 'package:punto_venta_app/features/pos/domain/entities/saved_order.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/clients/clients_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/utils/client_selection_helper.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/client/add_client_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/client/select_client_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/order/load_saved_orders_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/order/save_order_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/cashier_settings_dialog.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/settings/settings_dialog.dart';

class AppSidebar extends StatefulWidget {
  final String currentRoute;
  final bool isAdmin;
  final bool asDrawer;
  final VoidCallback? onLogout;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onMessagesPressed;
  final VoidCallback? onHistoryPressed;

  const AppSidebar({
    super.key,
    required this.currentRoute,
    this.isAdmin = false,
    this.asDrawer = false,
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
  bool _isSaveOrderDialogOpen = false;
  bool _isLoadSavedOrdersDialogOpen = false;
  bool _isSelectClientDialogOpen = false;
  bool _isAddClientDialogOpen = false;
  bool _isLogoutDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark;
        final sidebarBg = isDark
            ? AppColors.sidebarDarkBackground
            : AppColors.sidebarLightBackground;
        final sidebarSurface = isDark
            ? AppColors.sidebarDarkSurface
            : AppColors.sidebarLightSurface;
        final sidebarDivider = isDark
            ? AppColors.sidebarDarkDivider
            : AppColors.sidebarLightDivider;

        final showLabel = widget.asDrawer;

        return Container(
          width: widget.asDrawer
              ? double.infinity
              : AppDimensions.sidebarRailWidth,
          height: double.infinity,
          decoration: BoxDecoration(color: sidebarBg),
          child: SafeArea(
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
                    icon: Icons.point_of_sale,
                    isHighlighted: widget.currentRoute == RoutePaths.pos,
                    tooltip: 'Punto de Venta',
                    showLabel: showLabel,
                    onTap: () => _navigateTo(context, RoutePaths.pos),
                  ),
                ),
                const SizedBox(height: 8),
                // History / Reports (fixed)
                _buildNavItem(
                  context,
                  isSelected: widget.currentRoute == RoutePaths.reports,
                  isDark: isDark,
                  sidebarSurface: sidebarSurface,
                  child: SidebarItem(
                    icon: Icons.request_page_rounded,
                    isHighlighted: widget.currentRoute == RoutePaths.reports,
                    tooltip: 'Reportes',
                    showLabel: showLabel,
                    onTap:
                        widget.onHistoryPressed ??
                        () => _navigateTo(context, RoutePaths.reports),
                  ),
                ),
                const SizedBox(height: 8),
                // Product Labels (fixed)
                _buildNavItem(
                  context,
                  isSelected: widget.currentRoute == RoutePaths.productLabels,
                  isDark: isDark,
                  sidebarSurface: sidebarSurface,
                  child: SidebarItem(
                    icon: Icons.label_outlined,
                    isHighlighted:
                        widget.currentRoute == RoutePaths.productLabels,
                    tooltip: 'Etiquetas de Productos',
                    showLabel: showLabel,
                    onTap: () => _navigateTo(context, RoutePaths.productLabels),
                  ),
                ),
                const SizedBox(height: 8),
                _buildNavItem(
                  context,
                  isSelected:
                      widget.currentRoute == RoutePaths.supplierPayments,
                  isDark: isDark,
                  sidebarSurface: sidebarSurface,
                  child: SidebarItem(
                    isDisabled: true,
                    icon: Icons.local_shipping_outlined,
                    isHighlighted:
                        widget.currentRoute == RoutePaths.supplierPayments,
                    tooltip: 'Pagos a Proveedores',
                    showLabel: showLabel,
                    onTap: () =>
                        _navigateTo(context, RoutePaths.supplierPayments),
                  ),
                ),
                if (widget.isAdmin) ...[
                  const SizedBox(height: 8),
                  // Cobradores Pendientes (fixed)
                  _buildNavItem(
                    context,
                    isSelected:
                        widget.currentRoute == RoutePaths.pendingSettlements,
                    isDark: isDark,
                    sidebarSurface: sidebarSurface,
                    child: SidebarItem(
                      icon: Icons.attach_money_outlined,
                      isHighlighted:
                          widget.currentRoute == RoutePaths.pendingSettlements,
                      tooltip: 'Cobradores Pendientes',
                      showLabel: showLabel,
                      onTap:
                          widget.onHistoryPressed ??
                          () => _navigateTo(
                            context,
                            RoutePaths.pendingSettlements,
                          ),
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Middle scrollable items (only active in POS route)
                if (widget.currentRoute == RoutePaths.pos) ...[
                  Divider(
                    color: sidebarDivider,
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Guardar ticket
                          _buildNavItem(
                            context,
                            isSelected: _isSaveOrderDialogOpen,
                            isDark: isDark,
                            sidebarSurface: sidebarSurface,
                            child: SidebarItem(
                              icon: Icons.save_outlined,
                              isHighlighted: _isSaveOrderDialogOpen,
                              tooltip: 'Guardar Ticket',
                              showLabel: showLabel,
                              onTap: () => _handleSaveOrder(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Cargar ticket guardado
                          _buildNavItem(
                            context,
                            isSelected: _isLoadSavedOrdersDialogOpen,
                            isDark: isDark,
                            sidebarSurface: sidebarSurface,
                            child: SidebarItem(
                              icon: Icons.folder_open_outlined,
                              isHighlighted: _isLoadSavedOrdersDialogOpen,
                              tooltip: 'Cargar Ticket',
                              showLabel: showLabel,
                              onTap: () => _handleLoadOrder(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Seleccionar cliente
                          _buildNavItem(
                            context,
                            isSelected: _isSelectClientDialogOpen,
                            isDark: isDark,
                            sidebarSurface: sidebarSurface,
                            child: SidebarItem(
                              icon: Icons.person_search_outlined,
                              isHighlighted: _isSelectClientDialogOpen,
                              tooltip: 'Seleccionar Cliente',
                              showLabel: showLabel,
                              onTap: () => _handleSelectClient(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Agregar cliente
                          _buildNavItem(
                            context,
                            isSelected: _isAddClientDialogOpen,
                            isDark: isDark,
                            sidebarSurface: sidebarSurface,
                            child: SidebarItem(
                              isDisabled: true, // Deshabilitado temporalmente
                              icon: Icons.person_add_outlined,
                              isHighlighted: _isAddClientDialogOpen,
                              tooltip: 'Agregar Cliente',
                              showLabel: showLabel,
                              onTap: () => _handleAddClient(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Expanded empty area to push footer down on non-POS routes
                  const Expanded(child: SizedBox()),
                ],
                Divider(
                  color: sidebarDivider,
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                const SizedBox(height: 8),
                // Settings: admin → diálogo completo; cajero → solo pantalla cliente.
                _buildNavItem(
                  context,
                  isSelected: _isSettingsDialogOpen,
                  isDark: isDark,
                  sidebarSurface: sidebarSurface,
                  child: SidebarItem(
                    icon: Icons.settings_outlined,
                    isHighlighted: _isSettingsDialogOpen,
                    tooltip: 'Configuración',
                    showLabel: showLabel,
                    onTap:
                        widget.onSettingsPressed ??
                        () async {
                          setState(() => _isSettingsDialogOpen = true);
                          if (widget.isAdmin) {
                            await showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => BlocProvider.value(
                                value: context.read<ClientsBloc>(),
                                child: const SettingsDialog(),
                              ),
                            );
                          } else {
                            await showCashierSettingsDialog(context);
                          }
                          setState(() => _isSettingsDialogOpen = false);
                        },
                  ),
                ),

                _buildNavItem(
                  context,
                  isSelected: _isLogoutDialogOpen,
                  isDark: isDark,
                  sidebarSurface: sidebarSurface,
                  child: SidebarItem(
                    icon: Icons.logout_rounded,
                    isHighlighted: _isLogoutDialogOpen,
                    tooltip: 'Cerrar sesión',
                    showLabel: showLabel,
                    onTap: () async {
                      setState(() => _isLogoutDialogOpen = true);
                      await showLogoutDialog(context);
                      setState(() => _isLogoutDialogOpen = false);
                    },
                  ),
                ),

                // Theme switch
                Visibility(
                  visible: false,
                  child: _buildThemeToggle(
                    context,
                    isDark: mode == ThemeMode.dark,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return SvgPicture.asset('assets/icons/logo.svg', width: 48, height: 48);
  }

  Widget _buildThemeToggle(BuildContext context, {required bool isDark}) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Transform.scale(
            scale: 0.5,
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
    final height = widget.asDrawer ? 48.0 : 35.0;
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          if (isSelected)
            Positioned(
              left: 8,
              right: widget.asDrawer ? 8 : -16,
              top: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: sidebarSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.08,
                      ),
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
    MainScaffoldScope.maybeOf(context)?.closeDrawer();
    if (widget.currentRoute != route) {
      context.go(route);
    }
  }

  // Guardar ticket
  void _handleSaveOrder(BuildContext context) async {
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded && cartState.items.isNotEmpty) {
      setState(() => _isSaveOrderDialogOpen = true);
      await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => SaveOrderDialog(
          cartItems: cartState.items,
          cartLogItems: cartState.log,
          total: cartState.total,
          clientName: null,
        ),
      );
      setState(() => _isSaveOrderDialogOpen = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El carrito está vacío'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Cargar ticket guardado
  void _handleLoadOrder(BuildContext context) async {
    // Verificar si hay items en el carrito actual
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded && cartState.items.isNotEmpty) {
      // Preguntar si desea guardar el ticket actual

      final shouldSave = await showDialog<bool>(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ticket en curso'),
          content: const Text(
            '¿Desea guardar el ticket actual antes de cargar otro?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      );

      // Si el usuario eligió guardar, abrir el diálogo de guardar
      if (shouldSave == true && mounted) {
        await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) => SaveOrderDialog(
            cartItems: cartState.items,
            cartLogItems: cartState.log,
            total: cartState.total,
            clientName: null,
          ),
        );
      }

      // Si el usuario canceló el diálogo, no continuar
      if (shouldSave == null) return;
    }

    // Proceder a cargar el ticket guardado
    setState(() => _isLoadSavedOrdersDialogOpen = true);
    final result = await showDialog<SavedOrder>(
      barrierDismissible: false,
      context: context,
      builder: (context) => const LoadSavedOrdersDialog(),
    );

    if (result != null && mounted) {
      context.read<CartBloc>().add(
        ReplaceCart(items: result.items, log: result.logs, ticketId: result.id),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket "${result.name}" cargado exitosamente'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _isLoadSavedOrdersDialogOpen = false);
  }

  // Seleccionar cliente
  void _handleSelectClient(BuildContext context) async {
    setState(() => _isSelectClientDialogOpen = true);
    final result = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => BlocProvider.value(
        value: context.read<ClientsBloc>(),
        child: const SelectClientDialog(),
      ),
    );
    if (result != null && mounted) {
      await ClientSelectionHelper.selectClientAndUpdatePrices(context, result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente ${result.name} seleccionado'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _isSelectClientDialogOpen = false);
  }

  // Agregar cliente nuevo
  void _handleAddClient(BuildContext context) async {
    setState(() => _isAddClientDialogOpen = true);
    final added = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => BlocProvider.value(
        value: context.read<ClientsBloc>(),
        child: const AddClientDialog(),
      ),
    );
    if (added is Client && mounted) {
      await ClientSelectionHelper.selectClientAndUpdatePrices(context, added);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente ${added.name} agregado y seleccionado'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    setState(() => _isAddClientDialogOpen = false);
  }
}
