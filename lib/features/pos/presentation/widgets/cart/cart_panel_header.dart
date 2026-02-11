import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/core/constants/app_string.dart';

class CartPanelHeader extends StatelessWidget {
  const CartPanelHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingS),
      child: Row(
        children: [
          const SizedBox(width: AppDimensions.paddingS),
          Text(
            AppStrings.cartSummary,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
