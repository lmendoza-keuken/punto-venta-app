import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/utils.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';
import 'product_card.dart';

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
      //TODO:  Mover a un Widget aparte 
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'No se encontraron productos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Intenta cambiar los filtros o la búsqueda',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      );
    }

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
            //TODO:  Cambiar UIBloc a un valueNotifier 
            return ProductCard(
              product: product,
              isInDeleteMode: uiState.isDeleteMode,
              isCompact: crossAxisCount > 4,
              selectedQuantity: uiState.selectedQuantity,
              onTap: () => onProductTap(
                  product, uiState.selectedQuantity, uiState.isDeleteMode),
            );
          },
        );
      },
    );
  }
}
