import 'package:punto_venta_app/features/pos/domain/entities/sale_return.dart';

class SaleReturnModel {
  final int saleId;
  final int ncSaleId;
  final int reasonId;
  final double? total;
  final String? date;

  const SaleReturnModel({
    required this.saleId,
    required this.ncSaleId,
    required this.reasonId,
    this.total,
    this.date,
  });

  factory SaleReturnModel.fromJson(Map<String, dynamic> json) {
    return SaleReturnModel(
      saleId: json['sale_id'] as int,
      ncSaleId: json['nc_sale_id'] as int,
      reasonId: json['reason_id'] as int,
      total: (json['total'] as num?)?.toDouble(),
      date: json['date'] as String?,
    );
  }

  SaleReturn toEntity() {
    return SaleReturn(
      saleId: saleId,
      ncSaleId: ncSaleId,
      reasonId: reasonId,
      total: total,
      date: date,
    );
  }
}
