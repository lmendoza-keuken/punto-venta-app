import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/customer_display/domain/customer_display_snapshot.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_image.dart';

/// Héroe del último producto en la pantalla cliente (solo lectura).
class CustomerDisplayLastProductPreview extends StatelessWidget {
  const CustomerDisplayLastProductPreview({
    super.key,
    required this.product,
  });

  final CustomerDisplayLastProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionColor = product.isAdd ? AppColors.success : AppColors.error;
    final actionLabel = product.isAdd ? 'Agregado' : 'Eliminado';
    final actionIcon =
        product.isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final hasImage =
        product.imageUrl != null && product.imageUrl!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusL),
              border: Border.all(
                color: actionColor.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.grey.shade50),
                if (hasImage)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ProductImage(
                      key: ValueKey(
                        'cd-img-${product.entryId}-${product.productId}-${product.imageUrl}',
                      ),
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: Icon(
                        Icons.inventory_2,
                        size: 72,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.inventory_2,
                    size: 72,
                    color: Colors.grey.shade400,
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: actionColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(actionIcon, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          actionLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.paddingM),
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              product.quantityLabel,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: actionColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                product.lineTotal.formatToCurrency(),
                textAlign: TextAlign.right,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
