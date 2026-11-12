import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/product.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_bloc.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/product_labels/product_labels_event.dart';

class ProductLabelCard extends StatelessWidget {
  final Product product;
  final bool isSelected;

  const ProductLabelCard({
    super.key,
    required this.product,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: isSelected ? 6 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () {
          context
              .read<ProductLabelsBloc>()
              .add(ToggleProductSelection(product));
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 4),
              _buildCode(),
              const Spacer(flex: 1),
              if (product.barcodes != null && product.barcodes!.isNotEmpty) ...[
                _buildBarcode(),
                const SizedBox(height: 4),
              ],
              _buildPrice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            product.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.15,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (product.isOnSale)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'OFERTA',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        if (isSelected)
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
    );
  }

  Widget _buildCode() {
    return Text(
      'Código: ${product.id}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildBarcode() {
    return Row(
      children: [
        Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            product.barcodes!.first.barcode.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPrice() {
    final priceWithVat =
        ((product.price ?? 0) * (product.vat / 100)) + (product.price ?? 0);
    final regularPriceWithVat = product.regularPrice != null
        ? ((product.regularPrice! * (product.vat / 100)) +
            product.regularPrice!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (product.isOnSale && regularPriceWithVat != null)
          Row(
            children: [
              Flexible(
                child: Text(
                  regularPriceWithVat.formatToCurrency(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.grey[600],
                  ),
                ),
              ),
              if (regularPriceWithVat > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '-${(((regularPriceWithVat - priceWithVat) / regularPriceWithVat) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        if (product.isOnSale) const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: product.isOnSale
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              priceWithVat.formatToCurrency(),
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    product.isOnSale ? AppColors.warning : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
