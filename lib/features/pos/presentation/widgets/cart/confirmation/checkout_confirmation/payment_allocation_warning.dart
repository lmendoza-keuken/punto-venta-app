import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';

class PaymentAllocationWarning extends StatelessWidget {
  final double totalAmount;
  final double totalAllocated;

  const PaymentAllocationWarning({
    super.key,
    required this.totalAmount,
    required this.totalAllocated,
  });

  @override
  Widget build(BuildContext context) {
    final isShort = totalAllocated < totalAmount;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isShort
                  ? 'Falta asignar: \$ ${(totalAmount - totalAllocated).toStringAsFixed(2)}'
                  : 'El monto asignado supera el total por \$ ${(totalAllocated - totalAmount).toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
