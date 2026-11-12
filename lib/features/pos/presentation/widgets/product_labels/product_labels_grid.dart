import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/utils.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product_labels/product_label_card.dart';

class ProductLabelsGrid extends StatelessWidget {
  final ProductLabelsLoaded state;

  const ProductLabelsGrid({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (state.products.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = calculateCrossAxisCount(constraints.maxWidth);

        return GridView.builder(
          padding: EdgeInsets.all(
            constraints.maxWidth < LayoutSpec.compactBreakpoint
                ? AppDimensions.paddingM
                : AppDimensions.paddingL,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            // Sin imagen: altura fija compacta (no el ratio de product cards).
            mainAxisExtent: crossAxisCount >= 4
                ? 128
                : crossAxisCount >= 3
                    ? 136
                    : 148,
            crossAxisSpacing: calculateSpacing(crossAxisCount),
            mainAxisSpacing: calculateSpacing(crossAxisCount),
          ),
          itemCount: state.products.length,
          itemBuilder: (context, index) {
            final product = state.products[index];
            final isSelected =
                state.selectedProducts.any((p) => p.id == product.id);
            return ProductLabelCard(
              product: product,
              isSelected: isSelected,
              isCompact: crossAxisCount >= 2,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            state.searchQuery.isNotEmpty
                ? 'No se encontraron productos'
                : 'No hay productos disponibles',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
