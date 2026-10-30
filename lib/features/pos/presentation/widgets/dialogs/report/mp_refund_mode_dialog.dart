import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';

enum MpRefundMode { account, cash }

Future<MpRefundMode?> showMpRefundModeDialog(
  BuildContext context, {
  String providerLabel = 'Mercado Pago',
}) {
  return showDialog<MpRefundMode>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Reembolso $providerLabel'),
        content: Text(
          'Este ticket tiene un cobro con QR de $providerLabel.\n\n'
          '¿Cómo querés reintegrar el dinero?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(MpRefundMode.cash),
            child: const Text('Efectivo'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(MpRefundMode.account),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('A la cuenta ($providerLabel)'),
          ),
        ],
      );
    },
  );
}
