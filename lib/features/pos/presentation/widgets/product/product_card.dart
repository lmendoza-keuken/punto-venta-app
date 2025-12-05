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

  // Valores pasados desde el grid (sin dependencias a BLoC dentro del widget)
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        side: getBorderSide(
            canRemoveQuantity, hasInsufficientQuantity, isInDeleteMode),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        child: Container(
          padding:
              EdgeInsets.all(isCompact ? AppDimensions.paddingS : AppDimensions.paddingM),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges superiores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge de oferta
                      if (product.oferta)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'OFERTA',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: isCompact ? 7 : 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),

                      // Badge de cantidad en carrito
                      if (quantityInCart > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'En carrito: $quantityInCart',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: isCompact ? 7 : 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                    ],
                  ),

                  // Imagen placeholder
                  Expanded(
                    flex: isCompact ? 1 : 2,
                    child: Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(vertical: isCompact ? 2 : AppDimensions.paddingS),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusS),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2,
                            color: AppColors.textHint,
                            size: isCompact ? 20 : 30,
                          ),
                          if (!isCompact) ...[
                            const SizedBox(height: 4),
                            Text(
                              product.description.trim(),
                              style: const TextStyle(
                                fontSize: 8,
                                color: AppColors.textHint,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Información del producto
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del producto
                      Text(
                        product.description.trim(),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: isCompact ? 16 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: isCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Código: ${product.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: isCompact ? 14 : 10,
                              color: AppColors.textHint,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Precio y botón de acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            children: [
                              Text(
                                product.precio?.formatToCurrency() ?? '-',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: isCompact ? 16 : 14,
                                      fontWeight: FontWeight.bold,
                                      color: product.oferta ? AppColors.warning : AppColors.primary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        product.categoryDescription.trim(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),

              // Overlay de modo eliminar
              if (isInDeleteMode)
                Container(
                  decoration: BoxDecoration(
                    color: getOverlayColor(canRemoveQuantity, hasInsufficientQuantity),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          getOverlayIcon(canRemoveQuantity, hasInsufficientQuantity),
                          color: getOverlayIconColor(canRemoveQuantity, hasInsufficientQuantity),
                          size: isCompact ? 24 : 32,
                        ),
                        if (!isCompact && hasInsufficientQuantity) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Solo $quantityInCart\nen carrito',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            ],
          ),
        ),
      ),
    );
  }
}
