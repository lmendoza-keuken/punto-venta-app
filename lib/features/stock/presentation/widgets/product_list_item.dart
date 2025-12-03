import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddStock;
  final VoidCallback onRemoveStock;
  final VoidCallback onAdjustStock;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onAddStock,
    required this.onRemoveStock,
    required this.onAdjustStock,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stock < 10;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        side: BorderSide(
          color: isLowStock ? AppColors.warning.withOpacity(0.3) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isLowStock ? AppColors.warning.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
          ),
          child: Icon(
            Icons.inventory_2,
            color: isLowStock ? AppColors.warning : AppColors.primary,
          ),
        ),
        title: Text(
          product.descripcion,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Código: ${product.codigo}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Stock: ${product.stock}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isLowStock ? AppColors.warning : AppColors.success,
                  ),
                ),
                if (isLowStock) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'BAJO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Text(
          product.precio?.formatToCurrency() ?? '-',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAddStock,
                        icon: const Icon(Icons.add, size: 18, color: AppColors.success),
                        label: const Text('Agregar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRemoveStock,
                        icon: const Icon(Icons.remove, size: 18, color: AppColors.error),
                        label: const Text('Quitar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onAdjustStock,
                        icon: const Icon(Icons.tune, size: 18, color: AppColors.warning),
                        label: const Text('Ajustar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.warning,
                          side: const BorderSide(color: AppColors.warning),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.paddingS),
                // Edit and delete actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                        label: const Text('Eliminar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}