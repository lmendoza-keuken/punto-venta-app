import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/core/utils/utils.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isInDeleteMode;
  final bool isCompact;
  final int selectedQuantity;

  final int quantityInCart;
  final bool canRemoveQuantity;
  final bool hasInsufficientQuantity;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isInDeleteMode = false,
    this.isCompact = false,
    this.selectedQuantity = 1,
    required this.quantityInCart,
    required this.canRemoveQuantity,
    required this.hasInsufficientQuantity,
  });

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(AppDimensions.borderRadiusM);
    final hasImage =
        product.imageUrl != null && product.imageUrl!.trim().isNotEmpty;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: getBorderSide(
            canRemoveQuantity, hasInsufficientQuantity, isInDeleteMode),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: cardRadius,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: isCompact ? 3 : 4,
                  child: ColoredBox(
                    color: Colors.grey.shade100,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasImage)
                          CachedNetworkImage(
                            key: ValueKey(
                                'product-img-${product.id}-${product.imageUrl}'),
                            imageUrl: product.imageUrl!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            alignment: Alignment.center,
                            fadeInDuration: const Duration(milliseconds: 150),
                            placeholder: (context, url) => Center(
                              child: Icon(
                                Icons.inventory_2,
                                color: AppColors.textHint,
                                size: isCompact ? 28 : 40,
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.inventory_2,
                                color: AppColors.textHint,
                                size: isCompact ? 28 : 40,
                              ),
                            ),
                          )
                        else
                          Center(
                            child: Icon(
                              Icons.inventory_2,
                              color: AppColors.textHint,
                              size: isCompact ? 28 : 40,
                            ),
                          ),
                        Positioned(
                          top: 6,
                          left: 6,
                          right: 6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (product.isOnSale)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'OFERTA',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: isCompact ? 7 : 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              if (quantityInCart > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.info,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'En carrito: $quantityInCart',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: isCompact ? 7 : 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? AppDimensions.paddingS : AppDimensions.paddingM,
                    AppDimensions.paddingS,
                    isCompact ? AppDimensions.paddingS : AppDimensions.paddingM,
                    isCompact ? AppDimensions.paddingS : AppDimensions.paddingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.description.trim(),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: isCompact ? 14 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Código: ${product.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: isCompact ? 12 : 10,
                              color: AppColors.textHint,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.categoryDescription.trim(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.isOnSale && product.regularPrice != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                (((product.regularPrice ?? 0) *
                                            (product.vat / 100) +
                                        (product.regularPrice ?? 0)))
                                    .formatToCurrency(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: AppColors.textSecondary,
                                      fontSize: isCompact ? 12 : 11,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                          Text(
                            (((product.price ?? 0) * (product.vat / 100)) +
                                    (product.price ?? 0))
                                .formatToCurrency(),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: isCompact ? 14 : 13,
                                  fontWeight: FontWeight.bold,
                                  color: product.isOnSale
                                      ? AppColors.warning
                                      : AppColors.primary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isInDeleteMode)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: getOverlayColor(
                        canRemoveQuantity, hasInsufficientQuantity),
                    borderRadius: cardRadius,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          getOverlayIcon(
                              canRemoveQuantity, hasInsufficientQuantity),
                          color: getOverlayIconColor(
                              canRemoveQuantity, hasInsufficientQuantity),
                          size: isCompact ? 24 : 32,
                        ),
                        if (!isCompact && hasInsufficientQuantity) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Solo $quantityInCart\nen carrito',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (!isCompact && canRemoveQuantity) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Quitar $selectedQuantity',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
