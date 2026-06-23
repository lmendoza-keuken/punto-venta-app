import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';

class PaymentTaxBreakdown extends StatelessWidget {
  final double cartSubtotal;
  final double cartTotalIva;
  final double iibbAmount;
  final double vatPerceptionAmount;
  final double internalTaxAmount;

  const PaymentTaxBreakdown({
    super.key,
    required this.cartSubtotal,
    required this.cartTotalIva,
    required this.iibbAmount,
    required this.vatPerceptionAmount,
    required this.internalTaxAmount,
  });

  Widget _taxRow(String label, String value, {Color? color, bool isBold = true}) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: TextStyle(fontSize: 14, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _taxRow('Subtotal:', '\$ ${cartSubtotal.toStringAsFixed(2)}', isBold: false),
              const SizedBox(height: 8),
              _taxRow('IVA:', '\$ ${cartTotalIva.toStringAsFixed(2)}', isBold: false),
              if (iibbAmount > 0) ...[
                const SizedBox(height: 8),
                _taxRow(
                  'Percep. IIBB:',
                  '\$ ${iibbAmount.toStringAsFixed(2)}',
                  color: AppColors.info,
                ),
              ],
              if (vatPerceptionAmount > 0) ...[
                const SizedBox(height: 8),
                _taxRow(
                  'Percep. IVA:',
                  '\$ ${vatPerceptionAmount.toStringAsFixed(2)}',
                  color: AppColors.info,
                ),
              ],
              if (internalTaxAmount > 0) ...[
                const SizedBox(height: 8),
                _taxRow(
                  'Imp. Interno:',
                  '\$ ${internalTaxAmount.toStringAsFixed(2)}',
                  color: AppColors.info,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
