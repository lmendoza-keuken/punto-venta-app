class PdvConfig {
  final int? pdvId;
  final int? sucursalId;
  final String? branchNumber;

  const PdvConfig({
    this.pdvId,
    this.sucursalId,
    this.branchNumber,
  });

  PdvConfig copyWith({
    int? pdvId,
    int? sucursalId,
    String? branchNumber,
  }) {
    return PdvConfig(
      pdvId: pdvId ?? this.pdvId,
      sucursalId: sucursalId ?? this.sucursalId,
      branchNumber: branchNumber ?? this.branchNumber,
    );
  }

  Map<String, dynamic> toJson() => {
        'pdvId': pdvId,
        'sucursalId': sucursalId,
        'branchNumber': branchNumber,
      };

  factory PdvConfig.fromJson(Map<String, dynamic> json) => PdvConfig(
        pdvId: json['pdvId'] as int,
        sucursalId: json['sucursalId'] as int,
        branchNumber: json['branchNumber'] as String,
      );
}
