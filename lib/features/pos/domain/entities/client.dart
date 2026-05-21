import 'package:freezed_annotation/freezed_annotation.dart';

part 'client.freezed.dart';
part 'client.g.dart';

@freezed
class IibbTaxRate with _$IibbTaxRate {
  const factory IibbTaxRate({
    String? period,
    @JsonKey(name: 'customer_id') required int customerId,
    @JsonKey(name: 'province_id') required int provinceId,
    @JsonKey(name: 'tax_rate', fromJson: _taxRateFromJson) required double taxRate,
    @JsonKey(name: 'branch_id') required int branchId,
  }) = _IibbTaxRate;

  factory IibbTaxRate.fromJson(Map<String, dynamic> json) =>
      _$IibbTaxRateFromJson(json);
}

double _taxRateFromJson(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.parse(value);
  return 0.0;
}

@freezed
class Client with _$Client {
  const Client._();
  
  const factory Client({
    required int id,
    @JsonKey(name: 'business_name')
    required String name,
    String? document,
    String? phone,
    String? email,
    String? address,
    @JsonKey(name: 'list_id') int? listId,
    @JsonKey(name: 'vat_category_id') int? vatCategoryId,
    @JsonKey(name: 'iibb_category_id') String? iibbCategoryId,
    @JsonKey(name: 'province_id') int? provinceId,
    @JsonKey(name: 'city_id') int? cityId,
    String? cuit,
    String? dni,
    @JsonKey(name: 'iibb_tax_rates') List<IibbTaxRate>? iibbTaxRates,
  }) = _Client;

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);

}
