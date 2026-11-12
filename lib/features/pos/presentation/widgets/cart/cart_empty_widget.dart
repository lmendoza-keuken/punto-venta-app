import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';

class CartEmptyWidget extends StatelessWidget {
  final double? lastSaleChange;

  const CartEmptyWidget({super.key, this.lastSaleChange});

  @override
  Widget build(BuildContext context) {
    final change = lastSaleChange;
    final hasChange = change != null && change > 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasChange) ...[
              LastSaleChangeBanner(change: change),
              const SizedBox(height: AppDimensions.paddingL),
            ] else ...[
              Icon(Icons.shopping_cart_outlined,
                  size: 20, color: Colors.grey.shade400),
              const SizedBox(height: AppDimensions.paddingS),
            ],
            Text(
              'Carrito vacío',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              hasChange
                  ? 'Agrega un producto para continuar'
                  : 'Agrega productos para comenzar',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner destacado del vuelto de la última venta (para el cajero).
class LastSaleChangeBanner extends StatelessWidget {
  final double change;
  final bool dense;

  const LastSaleChangeBanner({
    super.key,
    required this.change,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dense) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.payments_outlined,
                color: AppColors.success, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Vuelto de la última venta:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            const Spacer(),
            Text(
              change.formatToCurrency(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.payments_outlined,
            size: 36,
            color: AppColors.success.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 8),
          Text(
            'Vuelto a devolver',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            change.formatToCurrency(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                  fontSize: 32,
                ),
          ),
        ],
      ),
    );
  }
}
