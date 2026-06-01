class PaymentDetails {
  final String? transferId;
  final String? bankId;
  final String? checkNumber;
  final String? accountOwner;
  final String? verificationId;

  const PaymentDetails({
    this.transferId,
    this.bankId,
    this.checkNumber,
    this.accountOwner,
    this.verificationId,
  });

  factory PaymentDetails.empty() => const PaymentDetails();

  factory PaymentDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return PaymentDetails.empty();
    }
    return PaymentDetails(
      transferId: json['transfer_id']?.toString(),
      bankId: json['bank_id']?.toString(),
      checkNumber: json['check_number']?.toString(),
      accountOwner: json['account_owner']?.toString(),
      verificationId: json['verification_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (transferId != null) map['transfer_id'] = transferId;
    if (bankId != null) map['bank_id'] = bankId;
    if (checkNumber != null) map['check_number'] = checkNumber;
    if (accountOwner != null) map['account_owner'] = accountOwner;
    if (verificationId != null) map['verification_id'] = verificationId;
    return map;
  }
}
