import 'package:freezed_annotation/freezed_annotation.dart';

part 'pdv_config_response_model.freezed.dart';
part 'pdv_config_response_model.g.dart';

@freezed
class PdvConfigResponseModel with _$PdvConfigResponseModel {
  const PdvConfigResponseModel._();

  const factory PdvConfigResponseModel({
    @JsonKey(name: 'branch_id') int? branchId,
    @JsonKey(name: 'company_id') int? companyId,
    @JsonKey(name: 'delivery_location_id') int? deliveryLocationId,
    @JsonKey(name: 'customer_id') int? customerId,
    @JsonKey(name: 'wallet_id') int? walletId,
    @JsonKey(name: 'wallet_seller_id') int? walletSellerId,
    @JsonKey(name: 'distribution_channel_id') int? distributionChannelId,
    @JsonKey(name: 'cuit') String? cuit,
    @JsonKey(name: 'sale_condition_id') String? saleConditionId,
    @JsonKey(name: 'type') String? type,
    @JsonKey(name: 'dni') String? dni,
    @JsonKey(name: 'vat_category_id') int? vatCategoryId,
    @JsonKey(name: 'shipment_id') int? shipmentId,
    @JsonKey(name: 'date') String? date,
    @JsonKey(name: 'id') int? id,
  }) = _PdvConfigResponseModel;

  factory PdvConfigResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PdvConfigResponseModelFromJson(json);
}
