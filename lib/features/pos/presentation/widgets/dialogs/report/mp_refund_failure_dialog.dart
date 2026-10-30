import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';

enum MpRefundFailureAction { retry, cash }

/// Diálogo tras fallar el reembolso a cuenta MP.
/// - [canRetry] true (1er fallo): Reintentar + Reembolso en efectivo
/// - [canRetry] false (2do fallo): solo Reembolso en efectivo
Future<MpRefundFailureAction?> showMpRefundFailureDialog(
  BuildContext context, {
  required String message,
  required bool canRetry,
}) {
  return showDialog<MpRefundFailureAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Expanded(child: Text('Reembolso QR')),
          ],
        ),
        content: Text(
          canRetry
              ? '$message\n\nPodés reintentar el reembolso a la cuenta '
                  'o continuar con reembolso en efectivo.'
              : '$message\n\nYa no se puede reintentar el reembolso a la '
                  'cuenta. Continuá con reembolso en efectivo.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(MpRefundFailureAction.cash),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reembolso en efectivo'),
          ),
          if (canRetry)
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(MpRefundFailureAction.retry),
              child: const Text('Reintentar'),
            ),
        ],
      );
    },
  );
}
