import 'package:flutter/material.dart';
import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';
import 'package:punto_venta_app/features/pos/presentation/widgets/cart/confirmation/checkout_confirmation/payment_method_details_controllers.dart';

IconData getPaymentMethodIcon(String description, String shortDescription) {
  final desc = description.toLowerCase();
  final shortDesc = shortDescription.toLowerCase();
  if (desc.contains('efectivo') || shortDesc.contains('efectivo')) {
    return Icons.attach_money;
  }
  if (desc.contains('tarjeta') ||
      shortDesc.contains('tarjeta') ||
      desc.contains('debito') ||
      shortDesc.contains('debito') ||
      desc.contains('credito') ||
      shortDesc.contains('credito') ||
      desc.contains('posnet') ||
      shortDesc.contains('posnet')) {
    return Icons.credit_card;
  }
  if (desc.contains('transferencia') ||
      shortDesc.contains('transferencia') ||
      desc.contains('banco') ||
      shortDesc.contains('banco')) {
    return Icons.account_balance;
  }
  if (desc.contains('qr') ||
      shortDesc.contains('qr') ||
      desc.contains('mercado') ||
      shortDesc.contains('mercado')) {
    return Icons.qr_code;
  }
  return Icons.payment;
}

class ChangeAndAmountsResult {
  final double receivedAmount;
  final double change;

  ChangeAndAmountsResult({required this.receivedAmount, required this.change});
}

ChangeAndAmountsResult calculateChangeAndAmounts(List<PaymentMethod> selectedPayments, double totalAmount) {
  double totalReceived = 0.0;
  double totalChange = 0.0;

  for (final pm in selectedPayments) {
    final isCash = pm.description.toLowerCase().contains('efectivo') ||
        pm.shortDescription.toLowerCase().contains('efectivo');
    final amount = pm.amount ?? 0.0;

    if (isCash) {
      final rec = pm.receivedAmount ?? amount;
      totalReceived += rec;
      if (rec > amount) {
        totalChange += (rec - amount);
      }
    } else {
      totalReceived += amount;
    }
  }

  return ChangeAndAmountsResult(
    receivedAmount: totalReceived,
    change: totalChange,
  );
}

void syncPaymentControllers({
  required List<PaymentMethod> selectedPayments,
  required List<TextEditingController> amountControllers,
  required List<TextEditingController> receivedControllers,
  required List<PaymentMethodDetailsControllers> detailsControllers,
}) {
  while (amountControllers.length > selectedPayments.length) {
    amountControllers.last.dispose();
    amountControllers.removeLast();
  }
  while (receivedControllers.length > selectedPayments.length) {
    receivedControllers.last.dispose();
    receivedControllers.removeLast();
  }
  while (detailsControllers.length > selectedPayments.length) {
    detailsControllers.last.dispose();
    detailsControllers.removeLast();
  }

  for (int i = 0; i < selectedPayments.length; i++) {
    final pm = selectedPayments[i];
    final amountStr = pm.amount != null ? pm.amount!.toStringAsFixed(2) : '';
    final receivedStr = pm.receivedAmount != null
        ? pm.receivedAmount!.toStringAsFixed(2)
        : '';
    final details = pm.details;

    if (i >= amountControllers.length) {
      amountControllers.add(TextEditingController(text: amountStr));
    }

    if (i >= receivedControllers.length) {
      receivedControllers.add(TextEditingController(text: receivedStr));
    }

    if (i >= detailsControllers.length) {
      final ctrl = PaymentMethodDetailsControllers();
      ctrl.accountOwner.text = details?.accountOwner ?? '';
      ctrl.bankId.text = details?.bankId ?? '';
      ctrl.checkNumber.text = details?.checkNumber ?? '';
      ctrl.transferId.text = details?.transferId ?? '';
      ctrl.verificationId.text = details?.verificationId ?? '';
      detailsControllers.add(ctrl);
    } else {
      final ctrl = detailsControllers[i];
      if (ctrl.accountOwner.text != (details?.accountOwner ?? '')) {
        ctrl.accountOwner.text = details?.accountOwner ?? '';
      }
      if (ctrl.bankId.text != (details?.bankId ?? '')) {
        ctrl.bankId.text = details?.bankId ?? '';
      }
      if (ctrl.checkNumber.text != (details?.checkNumber ?? '')) {
        ctrl.checkNumber.text = details?.checkNumber ?? '';
      }
      if (ctrl.transferId.text != (details?.transferId ?? '')) {
        ctrl.transferId.text = details?.transferId ?? '';
      }
      if (ctrl.verificationId.text != (details?.verificationId ?? '')) {
        ctrl.verificationId.text = details?.verificationId ?? '';
      }
    }
  }
}
