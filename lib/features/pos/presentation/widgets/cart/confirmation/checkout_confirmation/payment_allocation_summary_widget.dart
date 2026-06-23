import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';

class PaymentAllocationSummaryWidget extends StatelessWidget {
  final double totalAmount;
  final double totalAllocated;
  final double? change;

  const PaymentAllocationSummaryWidget({
    super.key,
    required this.totalAmount,
    required this.totalAllocated,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Venta:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                totalAmount.formatToCurrency(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Asignado:'),
              Text(
                totalAllocated.formatToCurrency(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: double.parse(totalAllocated.toStringAsFixed(2)) ==
                          double.parse(totalAmount.toStringAsFixed(2))
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
          if (change != null && change! > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vuelto / Cambio:',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  change!.formatToCurrency(),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
