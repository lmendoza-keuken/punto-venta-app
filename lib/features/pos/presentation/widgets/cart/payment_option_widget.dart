import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';

class PaymentOptionWidget extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;
  final IconData icon;

  const PaymentOptionWidget({
    super.key,
    required this.paymentMethod,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isEnabled
                  ? AppColors.success.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isEnabled
                    ? AppColors.success.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.2)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : (isEnabled
                        ? AppColors.success.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primary
                    : (isEnabled ? AppColors.success : Colors.grey),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                paymentMethod.shortDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isEnabled) ...[
              const SizedBox(height: 4),
              Text(
                'No disponible',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
