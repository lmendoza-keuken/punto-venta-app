import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product_labels/product_labels_search_bar.dart';

class ProductLabelsHeader extends StatelessWidget {
  const ProductLabelsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Etiquetas para gondolas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildActionButtons(),
            ],
          ),
          const SizedBox(height: 16),
          const ProductLabelsSearchBar(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<ProductLabelsBloc, ProductLabelsState>(
      builder: (context, state) {
        if (state is ProductLabelsLoaded &&
            state.selectedProducts.isNotEmpty) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${state.selectedProducts.length} seleccionado(s)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  context
                      .read<ProductLabelsBloc>()
                      .add(const ClearSelection());
                },
                icon: const Icon(Icons.clear, size: 16, color: Colors.red),
                label: const Text('Limpiar'),
                
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  context
                      .read<ProductLabelsBloc>()
                      .add(const PrintSelectedLabels());
                },
                icon: const Icon(Icons.print, size: 16, color: Colors.white,),
                label: const Text('Imprimir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
