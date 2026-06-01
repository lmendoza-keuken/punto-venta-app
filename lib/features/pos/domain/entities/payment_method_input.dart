import 'package:punto_venta_app/features/pos/domain/entities/payment_details.dart';

class PaymentMethodInput {
  final int id;
  final double amount;
  final PaymentDetails details;

  const PaymentMethodInput({
    required this.id,
    required this.amount,
    this.details = const PaymentDetails(),
  });

  factory PaymentMethodInput.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInput(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      details: PaymentDetails.fromJson(
        json['details'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'details': details.toJson(),
      };
}
