import 'package:freezed_annotation/freezed_annotation.dart';

part 'pos_request_model.freezed.dart';
part 'pos_request_model.g.dart';

@freezed
class PosRequestModel with _$PosRequestModel {
  factory PosRequestModel({
    @JsonKey(name: 'name') required String name,
    @Default(true) @JsonKey(name: 'fixed_amount') bool fixedAmount,
    @JsonKey(name: 'store_id') required int storeId,
    @JsonKey(name: 'external_store_id') required String externalStoreId,
    @JsonKey(name: 'external_id') required String externalId,
    @Default(621102) @JsonKey(name: 'category') int category,
  }) = _PosRequestModel;

  factory PosRequestModel.fromJson(Map<String, dynamic> json) =>
      _$PosRequestModelFromJson(json);
}
