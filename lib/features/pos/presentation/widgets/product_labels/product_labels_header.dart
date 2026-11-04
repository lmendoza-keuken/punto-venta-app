import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_event.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_state.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product_labels/product_labels_search_bar.dart';

class ProductLabelsHeader extends StatelessWidget {
  const ProductLabelsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = LayoutSpec.of(context).isCompact;

    return Container(
      padding: EdgeInsets.all(
        compact ? AppDimensions.paddingM : AppDimensions.paddingL,
      ),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact) ...[
            const Text(
              'Etiquetas para góndolas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            _buildSelectAllButton(compact: true),
            _buildActionButtons(compact: true),
          ] else
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Etiquetas para góndolas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildSelectAllButton(),
                const SizedBox(width: 8),
                _buildActionButtons(),
              ],
            ),
          const SizedBox(height: AppDimensions.paddingM),
          const ProductLabelsSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSelectAllButton({bool compact = false}) {
    return BlocBuilder<ProductLabelsBloc, ProductLabelsState>(
      builder: (context, state) {
        if (state is ProductLabelsLoaded && state.products.isNotEmpty) {
          final allSelected =
              state.selectedProducts.length == state.products.length;
          return Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: Icon(
                allSelected ? Icons.check_box : Icons.check_box_outline_blank,
              ),
              label: Text(
                allSelected
                    ? (compact ? 'Quitar selección' : 'Deseleccionar todas')
                    : (compact ? 'Seleccionar' : 'Seleccionar todas'),
              ),
              onPressed: () {
                final bloc = context.read<ProductLabelsBloc>();
                if (allSelected) {
                  bloc.add(ClearSelection());
                } else {
                  bloc.add(SelectAllVisibleProducts());
                }
              },
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActionButtons({bool compact = false}) {
    return BlocBuilder<ProductLabelsBloc, ProductLabelsState>(
      builder: (context, state) {
        if (state is! ProductLabelsLoaded ||
            state.selectedProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        final countChip = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            compact
                ? '${state.selectedProducts.length} sel.'
                : '${state.selectedProducts.length} seleccionado(s)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        );

        final clearButton = OutlinedButton.icon(
          onPressed: () {
            context.read<ProductLabelsBloc>().add(const ClearSelection());
          },
          icon: const Icon(Icons.clear, size: 16, color: Colors.red),
          label: const Text('Limpiar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
        );

        final printButton = ElevatedButton.icon(
          onPressed: () {
            context
                .read<ProductLabelsBloc>()
                .add(const PrintSelectedLabels());
          },
          icon: const Icon(Icons.print, size: 16, color: Colors.white),
          label: const Text('Imprimir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        );

        if (compact) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [countChip, clearButton, printButton],
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            countChip,
            const SizedBox(width: 12),
            clearButton,
            const SizedBox(width: 8),
            printButton,
          ],
        );
      },
    );
  }
}
