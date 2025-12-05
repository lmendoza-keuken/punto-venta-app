import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';

class CartEmptyWidget extends StatelessWidget {
  const CartEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: AppDimensions.paddingM),
          Text('Carrito vacío',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: AppDimensions.paddingS),
          Text('Agrega productos para comenzar',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}