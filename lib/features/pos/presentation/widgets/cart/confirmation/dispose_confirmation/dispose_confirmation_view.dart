import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/core/utils/extensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/dispose_reason.dart';

class DisposeConfirmationView extends StatelessWidget {
  final double totalAmount;
  final bool isLoadingReasons;
  final List<DisposeReason> disposeReasons;
  final int? selectedDisposeReasonId;
  final ValueChanged<int?> onDisposeReasonChanged;

  const DisposeConfirmationView({
    super.key,
    required this.totalAmount,
    required this.isLoadingReasons,
    required this.disposeReasons,
    required this.selectedDisposeReasonId,
    required this.onDisposeReasonChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motivo de Descarte',
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
        else if (disposeReasons.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No hay motivos de descarte configurados.',
              style: TextStyle(color: AppColors.error),
            ),
          )
        else ...[
          DropdownButtonFormField<int>(
            initialValue: selectedDisposeReasonId,
            decoration: const InputDecoration(
              labelText: 'Seleccione un motivo',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            items: disposeReasons
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
            onChanged: onDisposeReasonChanged,
          ),
          const SizedBox(height: 24),
          // const Divider(),
          // const SizedBox(height: 24),
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.brown.shade50,
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(
          //       color: Colors.brown.shade200,
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       const Text(
          //         'Monto estimado:',
          //         style: TextStyle(
          //           fontWeight: FontWeight.bold,
          //           fontSize: 15,
          //         ),
          //       ),
          //       Text(
          //         totalAmount.formatToCurrency(),
          //         style: TextStyle(
          //           fontWeight: FontWeight.bold,
          //           fontSize: 16,
          //           color: Colors.brown.shade700,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ],
    );
  }
}
