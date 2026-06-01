import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_dimensions.dart';
import 'package:punto_venta_app/features/pos/domain/entities/return_reason.dart';

class ReturnReasonDialog extends StatefulWidget {
  final List<ReturnReason> reasons;

  const ReturnReasonDialog({
    super.key,
    required this.reasons,
  });

  @override
  State<ReturnReasonDialog> createState() => _ReturnReasonDialogState();
}

class _ReturnReasonDialogState extends State<ReturnReasonDialog> {
  int? _selectedReasonId;

  @override
  void initState() {
    super.initState();
    if (widget.reasons.isNotEmpty) {
      _selectedReasonId = widget.reasons.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Anular ticket'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Seleccione el motivo de la devolución total:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          DropdownButtonFormField<int>(
            value: _selectedReasonId,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              border: OutlineInputBorder(),
            ),
            items: widget.reasons
                .map(
                  (reason) => DropdownMenuItem<int>(
                    value: reason.id,
                    child: Text(reason.description),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedReasonId = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedReasonId == null
              ? null
              : () => Navigator.of(context).pop(_selectedReasonId),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar anulación'),
        ),
      ],
    );
  }
}
