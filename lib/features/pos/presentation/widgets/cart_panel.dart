import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_flutter_app/core/constants/app_colors.dart';
import 'package:pos_flutter_app/core/constants/app_dimensions.dart';
import 'package:pos_flutter_app/core/constants/app_string.dart';
import 'package:pos_flutter_app/core/utils/extensions.dart';
import 'package:pos_flutter_app/core/widgets/custom_butom.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_event.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_state.dart';
import 'cart_item_widget.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 280;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              left: BorderSide(color: Colors.grey.shade200),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.borderRadiusL),
              bottomLeft: Radius.circular(AppDimensions.borderRadiusL),
            ),
          ),
          child: Card(
            margin: const EdgeInsets.all(AppDimensions.paddingS),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
            ),
            child: Column(
              children: [
                // Header del carrito
                _buildCartHeader(context, isCompact),

                // Lista de items del carrito
                Expanded(
                  child: BlocBuilder<CartBloc, CartState>(
                    builder: (context, state) {
                      if (state is CartLoaded) {
                        return _buildCartContent(context, state, isCompact);
                      }
                      return _buildEmptyCart(context, isCompact);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartHeader(BuildContext context, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(
          isCompact ? AppDimensions.paddingS : AppDimensions.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.borderRadiusL),
          topRight: Radius.circular(AppDimensions.borderRadiusL),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_cart,
            color: Colors.white,
          ),
          SizedBox(
              width:
                  isCompact ? AppDimensions.paddingS : AppDimensions.paddingM),
          Expanded(
            child: Text(
              AppStrings.cart,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: isCompact ? 16 : 18,
                  ),
            ),
          ),
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.items.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.totalItems}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: isCompact ? 12 : 14,
                        ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(
      BuildContext context, CartLoaded state, bool isCompact) {
    return Column(
      children: [
        // Headers de la tabla (solo si no es compacto)
        if (!isCompact)
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingS),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    AppStrings.article,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    AppStrings.quantity,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    AppStrings.amount,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

        // Lista de items
        Expanded(
          child: state.items.isEmpty
              ? _buildEmptyCart(context, isCompact)
              : ListView.builder(
                  padding: const EdgeInsets.all(AppDimensions.paddingS),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return CartItemWidget(
                      item: item,
                      isCompact: isCompact,
                      onQuantityChanged: (quantity) {
                        context.read<CartBloc>().add(
                              UpdateQuantity(item.product.id, quantity),
                            );
                      },
                      onRemove: () {
                        context.read<CartBloc>().add(
                              RemoveFromCart(item.product.id),
                            );
                      },
                    );
                  },
                ),
        ),

        // Botón vaciar carrito
        if (state.items.isNotEmpty)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: AppStrings.empty,
                onPressed: () {
                  context.read<CartBloc>().add(ClearCart());
                },
                backgroundColor: AppColors.error,
                height: isCompact ? 32 : 36,
              ),
            ),
          ),

        // Total
        Container(
          padding: EdgeInsets.all(
              isCompact ? AppDimensions.paddingS : AppDimensions.paddingM),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppDimensions.borderRadiusL),
              bottomRight: Radius.circular(AppDimensions.borderRadiusL),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.total}:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isCompact ? 16 : 18,
                    ),
              ),
              Text(
                state.total.formatToCurrency(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: isCompact ? 16 : 18,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isCompact) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: isCompact ? 48 : 64,
              color: Colors.grey.shade400,
            ),
            SizedBox(
                height: isCompact
                    ? AppDimensions.paddingS
                    : AppDimensions.paddingM),
            Text(
              'Carrito vacío',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: isCompact ? 14 : 16,
                  ),
            ),
            SizedBox(height: isCompact ? 4 : AppDimensions.paddingS),
            Text(
              'Agrega productos para comenzar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                    fontSize: isCompact ? 12 : 14,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
