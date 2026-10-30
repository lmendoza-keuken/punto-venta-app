import 'package:freezed_annotation/freezed_annotation.dart';

part 'pos_response_model.freezed.dart';
part 'pos_response_model.g.dart';

@freezed
class PosResponseModel with _$PosResponseModel {
  factory PosResponseModel({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'qr') QrModel? qr,
    @JsonKey(name: 'status') String? status,
    @JsonKey(name: 'date_created') String? dateCreated,
    @JsonKey(name: 'date_last_updated') String? dateLastUpdated,
    @JsonKey(name: 'uuid') String? uuid,
    @JsonKey(name: 'user_id') int? userId,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'fixed_amount') bool? fixedAmount,
    @JsonKey(name: 'category') int? category,
    @JsonKey(name: 'store_id') String? storeId,
    @JsonKey(name: 'external_store_id') String? externalStoreId,
    @JsonKey(name: 'external_id') String? externalId,
    @JsonKey(name: 'site') String? site,
    @JsonKey(name: 'qr_code') String? qrCode,
  }) = _PosResponseModel;

  factory PosResponseModel.fromJson(Map<String, dynamic> json) =>
      _$PosResponseModelFromJson(json);
}

@freezed
class QrModel with _$QrModel {
  factory QrModel({
    @JsonKey(name: 'image') String? image,
    @JsonKey(name: 'template_document') String? templateDocument,
    @JsonKey(name: 'template_image') String? templateImage,
  }) = _QrModel;

  factory QrModel.fromJson(Map<String, dynamic> json) =>
      _$QrModelFromJson(json);
}
