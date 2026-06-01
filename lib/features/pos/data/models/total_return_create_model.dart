class TotalReturnCreateModel {
  final int saleId;
  final int reasonId;

  const TotalReturnCreateModel({
    required this.saleId,
    required this.reasonId,
  });

  Map<String, dynamic> toJson() => {
        'sale_id': saleId,
        'reason_id': reasonId,
      };
}
