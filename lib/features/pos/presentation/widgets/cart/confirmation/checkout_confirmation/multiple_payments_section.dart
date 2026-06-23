import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/add_payment_method_button.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_allocation_summary_widget.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_allocation_warning.dart';

class MultiplePaymentsSection extends StatelessWidget {
  final List<Widget> paymentRows;
  final VoidCallback onAddMethodPressed;
  final double totalAmount;
  final double totalAllocated;
  final double? change;

  const MultiplePaymentsSection({
    super.key,
    required this.paymentRows,
    required this.onAddMethodPressed,
    required this.totalAmount,
    required this.totalAllocated,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...paymentRows,
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: AddPaymentMethodButton(
            onPressed: onAddMethodPressed,
          ),
        ),
        const SizedBox(height: 16),
        PaymentAllocationSummaryWidget(
          totalAmount: totalAmount,
          totalAllocated: totalAllocated,
          change: change,
        ),
        if (double.parse(totalAllocated.toStringAsFixed(2)) !=
            double.parse(totalAmount.toStringAsFixed(2))) ...[
          const SizedBox(height: 12),
          PaymentAllocationWarning(
            totalAmount: totalAmount,
            totalAllocated: totalAllocated,
          ),
        ],
      ],
    );
  }
}
