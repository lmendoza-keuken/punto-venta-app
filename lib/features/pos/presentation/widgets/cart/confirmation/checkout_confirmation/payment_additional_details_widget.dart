import 'package:flutter/material.dart';
import 'package:punto_venta_app/core/constants/app_colors.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_methods_detail_form.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_method_details_controllers.dart';

class PaymentAdditionalDetailsWidget extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final PaymentMethodDetailsControllers controllers;
  final bool isExpanded;
  final VoidCallback onExpansionToggled;
  final ValueChanged<String> onCheckNumberChanged;
  final ValueChanged<String> onTransferIdChanged;
  final ValueChanged<String> onVerificationIdChanged;

  const PaymentAdditionalDetailsWidget({
    super.key,
    required this.paymentMethod,
    required this.controllers,
    required this.isExpanded,
    required this.onExpansionToggled,
    required this.onCheckNumberChanged,
    required this.onTransferIdChanged,
    required this.onVerificationIdChanged,
  });

  @override
  Widget build(BuildContext context) {
    final desc = paymentMethod.description.toLowerCase();
    final shortDesc = paymentMethod.shortDescription.toLowerCase();

    final isCash = desc.contains('efectivo') || shortDesc.contains('efectivo');
    if (isCash) return const SizedBox.shrink();

    final isTransfer = desc.contains('transferencia') ||
        shortDesc.contains('transferencia') ||
        desc.contains('banco') ||
        shortDesc.contains('banco');
    final isCard = desc.contains('tarjeta') ||
        shortDesc.contains('tarjeta') ||
        desc.contains('debito') ||
        shortDesc.contains('debito') ||
        desc.contains('credito') ||
        shortDesc.contains('credito') ||
        desc.contains('posnet') ||
        shortDesc.contains('posnet');
    final isQR = desc.contains('qr') ||
        shortDesc.contains('qr') ||
        desc.contains('mercado') ||
        shortDesc.contains('mercado');
    final isCheck = desc.contains('cheque') || shortDesc.contains('cheque');

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onExpansionToggled,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Datos adicionales del pago',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(
                  left: 12, right: 12, bottom: 12, top: 4),
              child: Builder(
                builder: (context) {
                  final detailsForms = <Widget>[
                    if (isCheck)
                      PaymentMethodsDetailForm(
                        controller: controllers.checkNumber,
                        label: 'Número de cheque',
                        icon: Icons.pin_outlined,
                        onChanged: onCheckNumberChanged,
                      ),
                    if (isTransfer || isQR)
                      PaymentMethodsDetailForm(
                        controller: controllers.transferId,
                        label: 'ID de Transferencia/Operación',
                        icon: Icons.receipt_long_outlined,
                        onChanged: onTransferIdChanged,
                      ),
                    if (isCard || isQR)
                      PaymentMethodsDetailForm(
                        controller: controllers.verificationId,
                        label: isCard
                            ? 'Nro. de Lote/Cupón (Verificación)'
                            : 'ID de Verificación',
                        icon: Icons.verified_outlined,
                        onChanged: onVerificationIdChanged,
                      ),
                  ];

                  return Column(
                    children: [
                      for (int i = 0; i < detailsForms.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        detailsForms[i],
                      ],
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
