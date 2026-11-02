import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';

/// Logo MP / PVS (mismos assets que el confirmation panel del cajero).
class CustomerDisplayQrBrand extends StatelessWidget {
  const CustomerDisplayQrBrand({
    super.key,
    required this.label,
    this.height = 56,
  });

  final String label;
  final double height;

  static String? assetForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('mercado')) {
      return 'assets/images/mercadopago_logo.png';
    }
    if (lower.contains('pvs')) {
      return 'assets/images/pvs_logo.png';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final asset = assetForLabel(label);
    if (asset != null) {
      return Image.asset(
        asset,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _FallbackLabel(label: label),
      );
    }
    return _FallbackLabel(label: label);
  }
}

class _FallbackLabel extends StatelessWidget {
  const _FallbackLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.qr_code_2, size: 28, color: AppColors.primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
