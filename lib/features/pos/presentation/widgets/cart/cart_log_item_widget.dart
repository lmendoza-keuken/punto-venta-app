import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/cart_log_entry.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';

class CartLogItemWidget extends StatelessWidget {
  final CartLogEntry entry;

  const CartLogItemWidget({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isAdd = entry.type == CartActionType.add;
    final icon = isAdd ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final color = isAdd ? AppColors.success : AppColors.error;
    final sign = isAdd ? '+' : '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.item.product.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        (entry.item.isWeighted ?? false)
                            ? '$sign${entry.item.weightKg} kg'
                            : '$sign${entry.item.quantity}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '  •  ${(((entry.item.product.price ?? 0) * (entry.item.product.vat / 100)) + (entry.item.product.price ?? 0)).formatToCurrency()}  •  ${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$sign ${(entry.item.isWeighted ?? false) ? ((entry.item.pricePerKg ?? 0.0)).formatToCurrency() : ((((entry.item.product.price ?? 0.0) * (entry.item.product.vat / 100)) + (entry.item.product.price ?? 0.0)) * entry.item.quantity).formatToCurrency()}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
