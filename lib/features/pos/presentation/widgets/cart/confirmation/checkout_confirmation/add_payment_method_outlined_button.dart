import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';

class AddPaymentMethodOutlinedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddPaymentMethodOutlinedButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Agregar Otro Método'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
