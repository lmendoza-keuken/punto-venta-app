import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/product/product_image.dart';

class LastScannedProductPreview extends StatelessWidget {
  final CartLogEntry entry;
  final bool dense;

  const LastScannedProductPreview({
    super.key,
    required this.entry,
    this.dense = false,
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

    if (dense) {
      return _DensePreview(
        productName: product.name,
        productId: product.id,
        hasImage: hasImage,
        imageUrl: product.imageUrl,
        actionColor: actionColor,
        actionLabel: actionLabel,
        actionIcon: actionIcon,
        quantityLabel: quantityLabel,
        priceLine:
            '${unitPrice.formatToCurrency()}${isWeighted ? ' / kg' : ''}  ·  ${lineTotal.formatToCurrency()}',
        entryId: entry.id,
      );
    }

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
                    ProductImage(
                      key: ValueKey(
                        'scanner-img-${entry.id}-${product.id}-${product.imageUrl}',
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }
}

class _DensePreview extends StatelessWidget {
  final String productName;
  final dynamic productId;
  final bool hasImage;
  final String? imageUrl;
  final Color actionColor;
  final String actionLabel;
  final IconData actionIcon;
  final String quantityLabel;
  final String priceLine;
  final dynamic entryId;

  const _DensePreview({
    required this.productName,
    required this.productId,
    required this.hasImage,
    required this.imageUrl,
    required this.actionColor,
    required this.actionLabel,
    required this.actionIcon,
    required this.quantityLabel,
    required this.priceLine,
    required this.entryId,
  });

  @override
  Widget build(BuildContext context) {
    const imageSize = 72.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingS,
        vertical: AppDimensions.paddingS,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
          border: Border.all(
            color: actionColor.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
              child: SizedBox(
                width: imageSize,
                height: imageSize,
                child: hasImage
                    ? ProductImage(
                        key: ValueKey(
                          'scanner-dense-$entryId-$productId-$imageUrl',
                        ),
                        imageUrl: imageUrl!,
                        fit: BoxFit.contain,
                        width: imageSize,
                        height: imageSize,
                        placeholder: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: Icon(
                          Icons.inventory_2,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                      )
                    : Icon(
                        Icons.inventory_2,
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: actionColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(actionIcon, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              actionLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          quantityLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: actionColor,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                  ),
                  Text(
                    'Código: $productId  ·  $priceLine',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.2,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
