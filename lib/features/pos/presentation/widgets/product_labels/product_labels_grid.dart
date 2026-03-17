import 'package:flutter/material.dart';
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

    return GridView.builder(
      padding: const EdgeInsets.all(24.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final product = state.products[index];
        final isSelected =
            state.selectedProducts.any((p) => p.id == product.id);
        return ProductLabelCard(
          product: product,
          isSelected: isSelected,
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
