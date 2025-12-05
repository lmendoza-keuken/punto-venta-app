import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_string.dart';
import '../../../../../core/utils/extensions.dart';
import '../../../../../core/widgets/custom_butom.dart';

class CartSummary extends StatelessWidget {
  final double subtotal;
  final double totalIva;
  final double totalConIva;
  final VoidCallback onClear;

  const CartSummary({
    super.key,
    required this.subtotal,
    required this.totalIva,
    required this.totalConIva,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      child: Column(
        children: [
          const SizedBox(height: AppDimensions.paddingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: Theme.of(context).textTheme.bodyMedium),
              Text(subtotal.formatToCurrency(),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('IVA:', style: TextStyle(color: Colors.grey[700])),
              Text(totalIva.formatToCurrency(),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.total,
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(totalConIva.formatToCurrency(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: AppStrings.empty,
                  onPressed: onClear,
                  backgroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}