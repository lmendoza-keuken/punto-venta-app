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
    required String id,
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
  
  factory Client.fromBackendJson(Map<String, dynamic> json) {
    final String? cuitValue = json['cuit'] as String?;
    final String? dniValue = json['dni'] as String?;
    
    // Determinar el document basado en cuit o dni
    String? document;
    if (cuitValue != null && cuitValue.isNotEmpty) {
      document = cuitValue;
    } else if (dniValue != null && dniValue.isNotEmpty) {
      document = dniValue;
    }

    // Mapear las tasas de IIBB
    List<IibbTaxRate>? taxRates;
    if (json['iibb_tax_rates'] != null) {
      taxRates = (json['iibb_tax_rates'] as List)
          .map((item) => IibbTaxRate.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return Client(
      id: json['id'].toString(),
      name: json['business_name'] as String? ?? '',
      document: document,
      address: json['address'] as String?,
      listId: json['list_id'] as int?,
      vatCategoryId: json['vat_category_id'] as int?,
      iibbCategoryId: json['iibb_category_id'] as String?,
      provinceId: json['province_id'] as int?,
      cityId: json['city_id'] as int?,
      cuit: (cuitValue != null && cuitValue.isNotEmpty) ? cuitValue : null,
      dni: (dniValue != null && dniValue.isNotEmpty) ? dniValue : null,
      iibbTaxRates: taxRates,
      phone: null,
      email: null,
    );
  }
}
