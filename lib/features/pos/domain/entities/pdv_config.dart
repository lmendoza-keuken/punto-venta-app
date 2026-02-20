class PdvConfig {
  final int? pdvId;
  final int? branchId;
  final String? branchNumber;

  const PdvConfig({
    this.pdvId,
    this.branchId,
    this.branchNumber,
  });

  PdvConfig copyWith({
    int? pdvId,
    int? branchId,
    String? branchNumber,
  }) {
    return PdvConfig(
      pdvId: pdvId ?? this.pdvId,
      branchId: branchId ?? this.branchId,
      branchNumber: branchNumber ?? this.branchNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'delivery_location_id': pdvId,
        'branch_id': branchId,
        'branch_number': branchNumber,
      };

  Map<String, dynamic> toUpdateJson() => {
        'delivery_location_id': pdvId,
        'branch_id': branchId,
      };

  factory PdvConfig.fromJson(Map<String, dynamic> json) => PdvConfig(
        pdvId: json['delivery_location_id'] as int,
        branchId: json['branch_id'] as int,
        branchNumber: json['branch_number'] as String,
      );
}
