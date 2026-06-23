import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/return_reason.dart';

class ReturnConfirmationView extends StatelessWidget {
  final double totalAmount;
  final bool isLoadingReasons;
  final List<ReturnReason> returnReasons;
  final int? selectedReturnReasonId;
  final ValueChanged<int?> onReturnReasonChanged;

  const ReturnConfirmationView({
    super.key,
    required this.totalAmount,
    required this.isLoadingReasons,
    required this.returnReasons,
    required this.selectedReturnReasonId,
    required this.onReturnReasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motivo de Devolución',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        if (isLoadingReasons)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (returnReasons.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No hay motivos de devolución configurados en el sistema.',
              style: TextStyle(color: AppColors.error),
            ),
          )
        else ...[
          // si hay motivos , se muestra el dropdown y el demas contenido
          DropdownButtonFormField<int>(
            value: selectedReturnReasonId,
            decoration: const InputDecoration(
              labelText: 'Seleccione un motivo',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: returnReasons
                .map(
                  (reason) => DropdownMenuItem<int>(
                    value: reason.id,
                    child: Text(
                      reason.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                )
                .toList(),
            onChanged: onReturnReasonChanged,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monto a Devolver:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  totalAmount.formatToCurrency(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
