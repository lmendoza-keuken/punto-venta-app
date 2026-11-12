import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_event.dart';

class ProductLabelCard extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final bool isCompact;

  const ProductLabelCard({
    super.key,
    required this.product,
    required this.isSelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardRadius = BorderRadius.circular(AppDimensions.borderRadiusM);
    final priceWithVat =
        ((product.price ?? 0) * (product.vat / 100)) + (product.price ?? 0);
    final regularPriceWithVat = product.regularPrice != null
        ? ((product.regularPrice! * (product.vat / 100)) +
            product.regularPrice!)
        : null;

    return Card(
      elevation: isSelected ? 4 : 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: cardRadius,
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          context
              .read<ProductLabelsBloc>()
              .add(ToggleProductSelection(product));
        },
        borderRadius: cardRadius,
        child: Padding(
          padding: EdgeInsets.all(
            isCompact ? AppDimensions.paddingS : AppDimensions.paddingM,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.description.trim(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: isCompact ? 14 : 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.15,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.isOnSale) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'OFERTA',
                        style: TextStyle(
                          fontSize: isCompact ? 9 : 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Código: ${product.id}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: isCompact ? 13 : 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.barcodes != null && product.barcodes!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.barcode_reader,
                      size: isCompact ? 12 : 11,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        product.barcodes!.first.barcode.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: isCompact ? 13 : 12,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.categoryDescription.trim(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.isOnSale && regularPriceWithVat != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        regularPriceWithVat.formatToCurrency(),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    priceWithVat.formatToCurrency(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
      ),
    );
  }
}
