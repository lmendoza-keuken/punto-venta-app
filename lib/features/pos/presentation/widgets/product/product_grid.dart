import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/utils.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/empty_products_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_card.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/cart/cart_state.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Function(Product, int, bool) onProductTap;
  final bool isLoading;
  final int crossAxisCount;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.isLoading = false,
    this.crossAxisCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (products.isEmpty) {
      return const EmptyProducts();
    }

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        return BlocBuilder<UiBloc, UiState>(
          builder: (context, state) {
            final uiState = state as UiLoaded;

            return GridView.builder(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: calculateAspectRatio(crossAxisCount),
                crossAxisSpacing: calculateSpacing(crossAxisCount),
                mainAxisSpacing: calculateSpacing(crossAxisCount),
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];

                int quantityInCart = 0;
                if (cartState is CartLoaded) {
                  quantityInCart = cartState.items
                      .where((item) => item.product.id == product.id)
                      .fold(0, (sum, item) => sum + item.quantity);
                }

                final bool canRemoveQuantity = uiState.isDeleteMode &&
                    quantityInCart >= uiState.selectedQuantity;
                final bool hasInsufficientQuantity = uiState.isDeleteMode &&
                    quantityInCart > 0 &&
                    quantityInCart < uiState.selectedQuantity;

                return ProductCard(
                  product: product,
                  isInDeleteMode: uiState.isDeleteMode,
                  isCompact: crossAxisCount > 4,
                  selectedQuantity: uiState.selectedQuantity,
                  quantityInCart: quantityInCart,
                  canRemoveQuantity: canRemoveQuantity,
                  hasInsufficientQuantity: hasInsufficientQuantity,
                  onTap: () => onProductTap(
                      product, uiState.selectedQuantity, uiState.isDeleteMode),
                );
              },
            );
          },
        );
      },
    );
  }
}
