import 'package:punto_venta_app/core/utils/enums.dart';

class PaymentMethodDetails {
  final String? accountOwner;
  final String? bankId;
  final String? checkNumber;
  final String? transferId;
  final String? verificationId;
  final String? orderId;

  const PaymentMethodDetails({
    this.accountOwner,
    this.bankId,
    this.checkNumber,
    this.transferId,
    this.verificationId,
    this.orderId,
  });

  PaymentMethodDetails copyWith({
    String? accountOwner,
    String? bankId,
    String? checkNumber,
    String? transferId,
    String? verificationId,
    String? orderId,
  }) {
    return PaymentMethodDetails(
      accountOwner: accountOwner ?? this.accountOwner,
      bankId: bankId ?? this.bankId,
      checkNumber: checkNumber ?? this.checkNumber,
      transferId: transferId ?? this.transferId,
      verificationId: verificationId ?? this.verificationId,
      orderId: orderId ?? this.orderId,
    );
  }

  factory PaymentMethodDetails.fromJson(Map<String, dynamic> json) {
    return PaymentMethodDetails(
      accountOwner: json['account_owner'] as String?,
      bankId: json['bank_id'] as String?,
      checkNumber: json['check_number'] as String?,
      transferId: json['transfer_id'] as String?,
      verificationId: json['verification_id'] as String?,
      orderId: json['order_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (accountOwner != null) 'account_owner': accountOwner,
        if (bankId != null) 'bank_id': bankId,
        if (checkNumber != null) 'check_number': checkNumber,
        if (transferId != null) 'transfer_id': transferId,
        if (verificationId != null) 'verification_id': verificationId,
        if (orderId != null) 'order_id': orderId,
      };
}

class PaymentMethod {
  final int id;
  final String description;
  final String shortDescription;
  final String deleteAt;
  final double? amount;
  final double? receivedAmount;
  final PaymentMethodDetails? details;
  final QrType? qrType;

  const PaymentMethod({
    required this.id,
    required this.description,
    required this.shortDescription,
    required this.deleteAt,
    this.amount,
    this.receivedAmount,
    this.details,
    this.qrType,
  });

  PaymentMethod copyWith({
    int? id,
    String? description,
    String? shortDescription,
    String? deleteAt,
    double? amount,
    double? receivedAmount,
    bool clearReceivedAmount = false,
    PaymentMethodDetails? details,
    QrType? qrType,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      deleteAt: deleteAt ?? this.deleteAt,
      amount: amount ?? this.amount,
      receivedAmount:
          clearReceivedAmount ? null : (receivedAmount ?? this.receivedAmount),
      details: details ?? this.details,
      qrType: qrType ?? this.qrType,
    );
  }
}
