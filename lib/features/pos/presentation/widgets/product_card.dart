import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_flutter_app/core/constants/app_colors.dart';
import 'package:pos_flutter_app/core/constants/app_dimensions.dart';
import 'package:pos_flutter_app/core/utils/extensions.dart';
import 'package:pos_flutter_app/core/utils/utils.dart';
import 'package:pos_flutter_app/features/pos/domain/entities/product.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_bloc.dart';
import 'package:pos_flutter_app/features/pos/presentation/bloc/cart/cart_state.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isInDeleteMode;
  final bool isCompact;
  final int selectedQuantity;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isInDeleteMode = false,
    this.isCompact = false,
    this.selectedQuantity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cartState) {
        int quantityInCart = 0;
        if (cartState is CartLoaded) {
          quantityInCart = cartState.items
              .where((item) => item.product.id == product.id)
              .fold(0, (sum, item) => sum + item.quantity);
        }

        bool canRemoveQuantity =
            isInDeleteMode && quantityInCart >= selectedQuantity;
        bool hasInsufficientQuantity = isInDeleteMode &&
            quantityInCart > 0 &&
            quantityInCart < selectedQuantity;

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
              padding: EdgeInsets.all(
                  isCompact ? AppDimensions.paddingS : AppDimensions.paddingM),
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

                          // Badge de cantidad en carrito
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

                      // Imagen placeholder
                      Expanded(
                        flex: isCompact ? 2 : 3,
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(
                              vertical: isCompact ? 2 : AppDimensions.paddingS),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadiusS),
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
                                  product.marca,
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
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre del producto
                            Text(
                              product.descripcion.trim(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontSize: isCompact ? 14 : 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                              maxLines: isCompact ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Código: ${product.codigo}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: isCompact ? 12 : 8,
                                    color: AppColors.textHint,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const Spacer(),

                            // Precio y botón de acción
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.precio.formatToCurrency(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontSize: isCompact ? 16 : 14,
                                              fontWeight: FontWeight.bold,
                                              color: product.oferta
                                                  ? AppColors.warning
                                                  : AppColors.primary,
                                            ),
                                      ),
                                      Text(
                                        product.rubro,
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Overlay de modo eliminar
                  if (isInDeleteMode)
                    Container(
                      decoration: BoxDecoration(
                        color: getOverlayColor(
                            canRemoveQuantity, hasInsufficientQuantity),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.borderRadiusM),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
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
      },
    );
  }
}
