class FiscalIssuerData {
  final String? fiscalName;
  final String? cuit;
  final String? iibbCuit;
  final String? address;
  final String? postalCode;
  final String? activityStartDate;
  final String? vatCondition;
  final String? legend1;
  final String? legend2;

  const FiscalIssuerData({
    this.fiscalName,
    this.cuit,
    this.iibbCuit,
    this.address,
    this.postalCode,
    this.activityStartDate,
    this.vatCondition,
    this.legend1,
    this.legend2,
  });

  FiscalIssuerData copyWith({
    String? fiscalName,
    String? cuit,
    String? iibbCuit,
    String? address,
    String? postalCode,
    String? activityStartDate,
    String? vatCondition,
    String? legend1,
    String? legend2,
  }) {
    return FiscalIssuerData(
      fiscalName: fiscalName ?? this.fiscalName,
      cuit: cuit ?? this.cuit,
      iibbCuit: iibbCuit ?? this.iibbCuit,
      address: address ?? this.address,
      postalCode: postalCode ?? this.postalCode,
      activityStartDate: activityStartDate ?? this.activityStartDate,
      vatCondition: vatCondition ?? this.vatCondition,
      legend1: legend1 ?? this.legend1,
      legend2: legend2 ?? this.legend2,
    );
  }

  @override
  String toString() {
    return 'FiscalIssuerData(fiscalName: $fiscalName, cuit: $cuit, '
        'iibbCuit: $iibbCuit, address: $address, '
        'postalCode: $postalCode, activityStartDate: $activityStartDate, '
        'vatCondition: $vatCondition, legend1: $legend1, legend2: $legend2)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FiscalIssuerData &&
        other.fiscalName == fiscalName &&
        other.cuit == cuit &&
        other.iibbCuit == iibbCuit &&
        other.address == address &&
        other.postalCode == postalCode &&
        other.activityStartDate == activityStartDate &&
        other.vatCondition == vatCondition &&
        other.legend1 == legend1 &&
        other.legend2 == legend2;
  }

  @override
  int get hashCode {
    return fiscalName.hashCode ^
        cuit.hashCode ^
        iibbCuit.hashCode ^
        address.hashCode ^
        postalCode.hashCode ^
        activityStartDate.hashCode ^
        vatCondition.hashCode ^
        legend1.hashCode ^
        legend2.hashCode;
  }
}
