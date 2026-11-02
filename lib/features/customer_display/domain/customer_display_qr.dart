import 'package:punto_venta_app/features/pos/domain/entities/payment_method.dart';

/// Detecta medios de pago QR orientados a cliente (Mercado Pago / PVS / genérico QR).
bool isCustomerDisplayQrPayment(PaymentMethod method) {
  final desc = method.description.toLowerCase();
  final short = method.shortDescription.toLowerCase();
  return desc.contains('qr') ||
      short.contains('qr') ||
      desc.contains('mercado') ||
      short.contains('mercado') ||
      desc.contains('pvs') ||
      short.contains('pvs');
}

PaymentMethod? findCustomerDisplayQrPayment(List<PaymentMethod> payments) {
  for (final pm in payments) {
    if (isCustomerDisplayQrPayment(pm)) return pm;
  }
  return null;
}

/// Nombre amigable para la UI cliente.
String customerDisplayQrLabel(PaymentMethod method) {
  final desc = method.description.toLowerCase();
  final short = method.shortDescription.toLowerCase();
  if (desc.contains('mercado') || short.contains('mercado')) {
    return 'Mercado Pago';
  }
  if (desc.contains('pvs') || short.contains('pvs')) {
    return 'PVS';
  }
  final label = method.shortDescription.trim().isNotEmpty
      ? method.shortDescription.trim()
      : method.description.trim();
  return label.isEmpty ? 'Pago QR' : label;
}
