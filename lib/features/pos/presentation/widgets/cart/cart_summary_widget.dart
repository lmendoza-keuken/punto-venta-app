import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';
import 'package:punto_venta_app/core/widgets/custom_button.dart';
import 'package:punto_venta_app/features/pos/presentation/bloc/ui/ui_state.dart';

class CartSummary extends StatelessWidget {
  final double subtotal;
  final double totalIva;
  final double totalConIva;
  final CartMode cartMode;
  final VoidCallback onConfirm;
  final bool isConfirmEnabled;

  const CartSummary({
    super.key,
    required this.subtotal,
    required this.totalIva,
    required this.totalConIva,
    this.cartMode = CartMode.sale,
    required this.onConfirm,
    this.isConfirmEnabled = true,
  });

  String get _confirmLabel {
    switch (cartMode) {
      case CartMode.returnMode:
        return 'Devolución';
      case CartMode.disposeMode:
        return 'Descarte';
      case CartMode.sale:
        return AppStrings.confirm;
    }
  }

  Color get _confirmColor {
    switch (cartMode) {
      case CartMode.returnMode:
        return AppColors.warning;
      case CartMode.disposeMode:
        return Colors.brown.shade600;
      case CartMode.sale:
        return AppColors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Column(
        children: [
          CustomButton(
            height: 50,
            width: double.infinity,
            text: _confirmLabel,
            onPressed: isConfirmEnabled ? onConfirm : null,
            backgroundColor: isConfirmEnabled ? _confirmColor : Colors.grey,
            textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
