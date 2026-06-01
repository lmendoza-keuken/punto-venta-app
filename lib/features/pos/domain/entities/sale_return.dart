class SaleReturn {
  final int saleId;
  final int ncSaleId;
  final int reasonId;
  final double? total;
  final String? date;

  const SaleReturn({
    required this.saleId,
    required this.ncSaleId,
    required this.reasonId,
    this.total,
    this.date,
  });
}
