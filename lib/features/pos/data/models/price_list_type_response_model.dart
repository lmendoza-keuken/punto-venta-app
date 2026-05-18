import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_list_type_response_model.freezed.dart';
part 'price_list_type_response_model.g.dart';

@freezed
class PriceListTypeResponseModel with _$PriceListTypeResponseModel {
  const PriceListTypeResponseModel._();

  const factory PriceListTypeResponseModel({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'description') String? description,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'order_by_company') int? orderByCompany,
    @JsonKey(name: 'allows_update') bool? allowsUpdate,
    @JsonKey(name: 'is_deleted') bool? isDeleted,
    @JsonKey(name: 'max_discount_per_item') int? maxDiscountPerItem,
    @JsonKey(name: 'max_discount_total') int? maxDiscountTotal,
    @JsonKey(name: 'only_bulk') bool? onlyBulk,
    @JsonKey(name: 'deletion_date') String? deletionDate,
    @JsonKey(name: 'seller_commission') String? sellerCommission,
    @JsonKey(name: 'currency_id') int? currencyId,
    
  }) = _PriceListTypeResponseModel;

  factory PriceListTypeResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PriceListTypeResponseModelFromJson(json);
}
