import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';

class LastScannedProductPreview extends StatelessWidget {
  final CartLogEntry entry;

  const LastScannedProductPreview({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final isAdd = entry.type == CartActionType.add;
    final actionColor = isAdd ? AppColors.success : AppColors.error;
    final actionLabel = isAdd ? 'Agregado' : 'Eliminado';
    final actionIcon =
        isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final sign = isAdd ? '+' : '-';

    final product = entry.item.product;
    final isWeighted = entry.item.isWeighted ?? false;
    final hasImage =
        product.imageUrl != null && product.imageUrl!.trim().isNotEmpty;

    final basePrice = product.price ?? 0.0;
    final vatRate = product.vat / 100.0;
    final internalTax = product.internalTax;
    final fractional = product.fractional ?? 1;

    double unitPrice = basePrice * (1 + vatRate);
    if (internalTax > 0) {
      unitPrice += internalTax * fractional;
    }

    final lineTotal = isWeighted
        ? unitPrice * (entry.item.weightKg ?? 0.0)
        : unitPrice * entry.item.quantity;

    final quantityLabel = isWeighted
        ? '$sign${entry.item.weightKg ?? 0} kg'
        : '$sign${entry.item.quantity}';

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(AppDimensions.borderRadiusM),
                border: Border.all(
                  color: actionColor.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CachedNetworkImage(
                      key: ValueKey(
                        'scanner-img-${entry.id}-${product.id}-${product.imageUrl}',
                      ),
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      fadeInDuration: const Duration(milliseconds: 150),
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Icon(
                        Icons.inventory_2,
                        size: 72,
                        color: Colors.grey.shade400,
                      ),
                    )
                  else
                    Icon(
                      Icons.inventory_2,
                      size: 72,
                      color: Colors.grey.shade400,
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(actionIcon, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            actionLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Código: ${product.id}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            quantityLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: actionColor,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${unitPrice.formatToCurrency()}${isWeighted ? ' / kg' : ''}  ·  ${lineTotal.formatToCurrency()}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }
}
