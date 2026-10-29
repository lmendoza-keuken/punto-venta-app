import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/dialogs/refund/refund_dialog.dart';

class CartPanelHeader extends StatelessWidget {
  const CartPanelHeader({super.key});

  void _changeMode(BuildContext context, CartMode mode) {
    context.read<UiBloc>().add(SetCartMode(mode));
    context.read<CartBloc>().add(ClearCart());
  }

  String _modeLabel(CartMode mode) {
    switch (mode) {
      case CartMode.sale:
        return 'Venta';
      case CartMode.returnMode:
        return 'Devolución';
      case CartMode.disposeMode:
        return 'Descarte';
    }
  }

  void _showChangeModeConfirmation(BuildContext context, CartMode toMode) {
    final cartState = context.read<CartBloc>().state;
    final hasItems = cartState is CartLoaded && cartState.items.isNotEmpty;

    if (!hasItems) {
      _changeMode(context, toMode);
      return;
    }

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpiar Pedido'),
        content: Text(
          'Al cambiar a modo ${_modeLabel(toMode)}, '
          'se limpiará el pedido actual. ¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _changeMode(context, toMode);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showClearCartConfirmation(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Limpiar Pedido'),
        content: const Text('¿Está seguro de que desea limpiar el carrito?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CartBloc>().add(ClearCart());
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Color _modeColor(CartMode mode) {
    switch (mode) {
      case CartMode.sale:
        return AppColors.primary;
      case CartMode.returnMode:
        return AppColors.warning;
      case CartMode.disposeMode:
        return Colors.brown.shade600;
    }
  }

  IconData _modeIcon(CartMode mode) {
    switch (mode) {
      case CartMode.sale:
        return Icons.shopping_cart_outlined;
      case CartMode.returnMode:
        return Icons.assignment_return_outlined;
      case CartMode.disposeMode:
        return Icons.delete_forever_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          final total = cartState is CartLoaded ? cartState.totalConIva : 0.0;
          final hasItems = cartState is CartLoaded &&
              (cartState.items.isNotEmpty || cartState.log.isNotEmpty);

          return BlocBuilder<UiBloc, UiState>(
            builder: (context, uiState) {
              final cartMode =
                  uiState is UiLoaded ? uiState.cartMode : CartMode.sale;
              final modeColor = _modeColor(cartMode);

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.cartSummary,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                _modeIcon(cartMode),
                                size: 14,
                                color: modeColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _modeLabel(cartMode),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: modeColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.menu, color: Colors.black87),
                            tooltip: 'Cambiar modo / vaciar / reintegro',
                            onSelected: (value) {
                              if (value == 'venta' &&
                                  cartMode != CartMode.sale) {
                                _showChangeModeConfirmation(
                                    context, CartMode.sale);
                              } else if (value == 'devolucion' &&
                                  cartMode != CartMode.returnMode) {
                                _showChangeModeConfirmation(
                                    context, CartMode.returnMode);
                              } else if (value == 'descarte' &&
                                  cartMode != CartMode.disposeMode) {
                                _showChangeModeConfirmation(
                                    context, CartMode.disposeMode);
                              } else if (value == 'vaciar') {
                                _showClearCartConfirmation(context);
                              } else if (value == 'reintegro') {
                                showRefundDialog(context);
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              _modeMenuItem(
                                value: 'venta',
                                label: 'Venta',
                                icon: Icons.shopping_cart_outlined,
                                selected: cartMode == CartMode.sale,
                                selectedColor: AppColors.primary,
                              ),
                              _modeMenuItem(
                                value: 'devolucion',
                                label: 'Devolución',
                                icon: Icons.assignment_return_outlined,
                                selected: cartMode == CartMode.returnMode,
                                selectedColor: AppColors.warning,
                              ),
                              _modeMenuItem(
                                value: 'descarte',
                                label: 'Descarte (mal estado)',
                                icon: Icons.delete_forever_outlined,
                                selected: cartMode == CartMode.disposeMode,
                                selectedColor: Colors.brown.shade600,
                              ),
                              const PopupMenuItem<String>(
                                value: 'reintegro',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.monetization_on_outlined,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Reintegro de dinero',
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'vaciar',
                                enabled: hasItems,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: hasItems
                                          ? AppColors.error
                                          : Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Vaciar',
                                      style: TextStyle(
                                        color: hasItems
                                            ? AppColors.error
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.paddingS),
                    decoration: BoxDecoration(
                      color: modeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: modeColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        total.formatToCurrency(),
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: modeColor,
                                  fontSize: 36,
                                ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _modeMenuItem({
    required String value,
    required String label,
    required IconData icon,
    required bool selected,
    required Color selectedColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: selected ? selectedColor : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? selectedColor : Colors.black87,
            ),
          ),
          if (selected) ...[
            const Spacer(),
            Icon(Icons.check, color: selectedColor, size: 18),
          ],
        ],
      ),
    );
  }
}
